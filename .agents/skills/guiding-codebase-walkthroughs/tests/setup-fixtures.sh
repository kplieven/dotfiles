#!/usr/bin/env bash
# Builds a layered Rust controller codebase for the guiding-codebase-walkthroughs scenarios.
# Usage: bash setup-fixtures.sh <root-dir>
set -euo pipefail

root="${1:?usage: setup-fixtures.sh <root-dir>}"
rm -rf "$root"
mkdir -p "$root/controller/src"
r="$root/controller"

cat > "$r/Cargo.toml" <<'EOF'
[package]
name = "tanteo-controller"
version = "0.1.0"
edition = "2021"

[dependencies]
axum = "0.7"
tokio = { version = "1", features = ["full"] }
futures = "0.3"
reqwest = { version = "0.12", features = ["json", "stream"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
async-trait = "0.1"
EOF

cat > "$r/src/main.rs" <<'EOF'
mod api;
mod convergence;
mod events;
mod nomad;
mod runtime;
mod service;

use std::sync::Arc;

use convergence::DesiredStateConverger;
use nomad::{NomadClient, NomadDependencies};
use service::ControllerService;

#[tokio::main]
async fn main() {
    let nomad = Arc::new(NomadClient::new(std::env::var("NOMAD_ADDR").unwrap_or_else(|_| "http://localhost:4646".into())));
    let deps = NomadDependencies::new(nomad.clone());
    let converger = Arc::new(DesiredStateConverger::new(deps));
    let service = Arc::new(ControllerService::new(converger.clone()));

    tokio::spawn(events::watch_and_converge(nomad.clone(), converger.clone()));

    let app = api::router(service);
    let listener = tokio::net::TcpListener::bind("127.0.0.1:4444").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
EOF

cat > "$r/src/api.rs" <<'EOF'
use std::sync::Arc;

use axum::{extract::State, http::StatusCode, routing::{get, put}, Json, Router};

use crate::runtime::ConfigurationRuntime;
use crate::service::{ApplyResponse, ControllerService};

pub fn router<R: ConfigurationRuntime + 'static>(service: Arc<ControllerService<R>>) -> Router {
    Router::new()
        .route("/v1/configuration", put(apply::<R>))
        .route("/v1/status", get(status::<R>))
        .with_state(service)
}

async fn apply<R: ConfigurationRuntime>(
    State(service): State<Arc<ControllerService<R>>>,
    body: axum::body::Bytes,
) -> Result<Json<ApplyResponse>, (StatusCode, String)> {
    service.apply(body.to_vec()).await.map(Json).map_err(|e| (StatusCode::BAD_GATEWAY, e.to_string()))
}

async fn status<R: ConfigurationRuntime>(
    State(service): State<Arc<ControllerService<R>>>,
) -> Result<Json<ApplyResponse>, (StatusCode, String)> {
    service.status().await.map(Json).map_err(|e| (StatusCode::BAD_GATEWAY, e.to_string()))
}
EOF

cat > "$r/src/runtime.rs" <<'EOF'
use async_trait::async_trait;

use crate::service::{ApplyResponse, ServiceError};

/// What the HTTP service needs from whatever actually applies configuration.
#[async_trait]
pub trait ConfigurationRuntime: Send + Sync {
    async fn submit(&self, config: Vec<u8>) -> Result<ApplyResponse, ServiceError>;
    async fn readback(&self) -> Result<ApplyResponse, ServiceError>;
}
EOF

cat > "$r/src/service.rs" <<'EOF'
use std::sync::Arc;

use serde::Serialize;

use crate::runtime::ConfigurationRuntime;

#[derive(Debug, Serialize, Clone)]
pub struct NodeStatus { pub node_id: String, pub desired_generation: u64, pub applied_generation: u64 }

#[derive(Debug, Serialize, Clone)]
pub struct ApplyResponse { pub generation: u64, pub nodes: Vec<NodeStatus> }

#[derive(Debug)]
pub enum ServiceError { Invalid(String), Unavailable(String) }

impl std::fmt::Display for ServiceError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self { Self::Invalid(m) => write!(f, "invalid: {m}"), Self::Unavailable(m) => write!(f, "unavailable: {m}") }
    }
}

pub struct ControllerService<R: ConfigurationRuntime> { runtime: Arc<R> }

impl<R: ConfigurationRuntime> ControllerService<R> {
    pub fn new(runtime: Arc<R>) -> Self { Self { runtime } }

    pub async fn apply(&self, body: Vec<u8>) -> Result<ApplyResponse, ServiceError> {
        if body.is_empty() { return Err(ServiceError::Invalid("empty configuration".into())); }
        self.runtime.submit(body).await
    }

    pub async fn status(&self) -> Result<ApplyResponse, ServiceError> { self.runtime.readback().await }
}
EOF

cat > "$r/src/convergence.rs" <<'EOF'
use async_trait::async_trait;
use tokio::sync::RwLock;

use crate::runtime::ConfigurationRuntime;
use crate::service::{ApplyResponse, NodeStatus, ServiceError};

/// Infrastructure the converger needs; implemented for Nomad in nomad.rs.
#[async_trait]
pub trait ReconcilerDependencies: Send + Sync {
    async fn list_nodes(&self) -> Result<Vec<String>, String>;
    async fn applied_generation(&self, node: &str) -> Result<u64, String>;
    async fn push_config(&self, node: &str, generation: u64, config: &[u8]) -> Result<(), String>;
}

struct DesiredState { generation: u64, config: Vec<u8> }

pub struct DesiredStateConverger<D: ReconcilerDependencies> {
    deps: D,
    desired: RwLock<Option<DesiredState>>,
}

impl<D: ReconcilerDependencies> DesiredStateConverger<D> {
    pub fn new(deps: D) -> Self { Self { deps, desired: RwLock::new(None) } }

    /// Bring every node to the desired generation. Safe to call repeatedly.
    pub async fn converge(&self) -> Result<ApplyResponse, String> {
        let guard = self.desired.read().await;
        let Some(desired) = guard.as_ref() else { return Ok(ApplyResponse { generation: 0, nodes: vec![] }) };
        let mut nodes = Vec::new();
        for node in self.deps.list_nodes().await? {
            let applied = self.deps.applied_generation(&node).await?;
            if applied < desired.generation {
                self.deps.push_config(&node, desired.generation, &desired.config).await?;
            }
            let applied = self.deps.applied_generation(&node).await?;
            nodes.push(NodeStatus { node_id: node, desired_generation: desired.generation, applied_generation: applied });
        }
        Ok(ApplyResponse { generation: desired.generation, nodes })
    }
}

#[async_trait]
impl<D: ReconcilerDependencies> ConfigurationRuntime for DesiredStateConverger<D> {
    async fn submit(&self, config: Vec<u8>) -> Result<ApplyResponse, ServiceError> {
        {
            let mut desired = self.desired.write().await;
            let generation = desired.as_ref().map_or(1, |d| d.generation + 1);
            *desired = Some(DesiredState { generation, config });
        }
        self.converge().await.map_err(ServiceError::Unavailable)
    }

    async fn readback(&self) -> Result<ApplyResponse, ServiceError> {
        self.converge().await.map_err(ServiceError::Unavailable)
    }
}
EOF

cat > "$r/src/nomad.rs" <<'EOF'
use std::sync::Arc;

use async_trait::async_trait;

use crate::convergence::ReconcilerDependencies;

pub struct NomadClient { pub addr: String, pub http: reqwest::Client }

impl NomadClient {
    pub fn new(addr: String) -> Self { Self { addr, http: reqwest::Client::new() } }
}

pub struct NomadDependencies { client: Arc<NomadClient> }

impl NomadDependencies {
    pub fn new(client: Arc<NomadClient>) -> Self { Self { client } }
}

#[async_trait]
impl ReconcilerDependencies for NomadDependencies {
    async fn list_nodes(&self) -> Result<Vec<String>, String> {
        let url = format!("{}/v1/allocations?filter=JobID==\"tanteo\"", self.client.addr);
        let allocs: Vec<serde_json::Value> = self.client.http.get(url).send().await.map_err(|e| e.to_string())?
            .json().await.map_err(|e| e.to_string())?;
        Ok(allocs.iter().filter_map(|a| a["NodeID"].as_str().map(String::from)).collect())
    }

    async fn applied_generation(&self, node: &str) -> Result<u64, String> {
        let url = format!("{}/v1/var/tanteo/{}", self.client.addr, node);
        let v: serde_json::Value = self.client.http.get(url).send().await.map_err(|e| e.to_string())?
            .json().await.map_err(|e| e.to_string())?;
        Ok(v["Items"]["generation"].as_str().and_then(|g| g.parse().ok()).unwrap_or(0))
    }

    async fn push_config(&self, node: &str, generation: u64, config: &[u8]) -> Result<(), String> {
        let url = format!("{}/v1/var/tanteo/{}", self.client.addr, node);
        let body = serde_json::json!({ "Items": { "generation": generation.to_string(), "config": String::from_utf8_lossy(config) } });
        self.client.http.put(url).json(&body).send().await.map_err(|e| e.to_string())?;
        Ok(())
    }
}
EOF

cat > "$r/src/events.rs" <<'EOF'
use std::sync::Arc;
use std::time::Duration;

use futures::StreamExt;

use crate::convergence::{DesiredStateConverger, ReconcilerDependencies};
use crate::nomad::NomadClient;

/// Long-poll Nomad's event stream; any allocation event triggers a convergence pass.
pub async fn watch_and_converge<D: ReconcilerDependencies>(nomad: Arc<NomadClient>, converger: Arc<DesiredStateConverger<D>>) {
    let mut last_index = 0u64;
    loop {
        let url = format!("{}/v1/event/stream?topic=Allocation&index={}", nomad.addr, last_index);
        let Ok(resp) = nomad.http.get(url).send().await else {
            tokio::time::sleep(Duration::from_secs(5)).await;
            continue;
        };
        let mut stream = resp.bytes_stream();
        let mut buffer = String::new();
        while let Some(Ok(chunk)) = stream.next().await {
            buffer.push_str(&String::from_utf8_lossy(&chunk));
            while let Some(idx) = buffer.find('\n') {
                let line: String = buffer.drain(..=idx).collect();
                if line.trim().is_empty() { continue; } // heartbeat
                if let Ok(batch) = serde_json::from_str::<serde_json::Value>(&line) {
                    last_index = batch["Index"].as_u64().unwrap_or(last_index);
                    let _ = converger.converge().await;
                }
            }
        }
    }
}
EOF

git -C "$r" init -q -b main
git -C "$r" -c user.name=Karel -c user.email=karel@example.com add -A
git -C "$r" -c user.name=Karel -c user.email=karel@example.com -c commit.gpgsign=false commit -q -m "feat: initial controller"
echo "fixtures ready in $root"
