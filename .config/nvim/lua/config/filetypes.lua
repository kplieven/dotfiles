-- Treat any file whose name contains "Dockerfile" as a dockerfile, so that
-- docker-language-server attaches to things like `my-Dockerfile`,
-- `Dockerfile-prod` or `Dockerfile_old` that Neovim's built-in detection misses.
-- Negative priority makes this a fallback: the built-in rules still win first.
vim.filetype.add({
    pattern = {
        ['.*[Dd]ockerfile.*'] = { 'dockerfile', { priority = -1 } },
    },
})
