local clang_format_filetypes = {
    c = true,
    cpp = true,
    objc = true,
    objcpp = true,
    h = true,
}

local function find_clang_format(start_path)
    local matches = vim.fs.find('.clang-format', {
        path = start_path,
        upward = true,
        stop = vim.loop.os_homedir(),
    })

    return matches[1]
end

local function parse_clang_format(path)
    local settings = {
        indent_width = nil,
        tab_width = nil,
        use_tab = nil,
    }

    for _, line in ipairs(vim.fn.readfile(path)) do
        if not line:match('^%s*#') then
            local key, value = line:match('^%s*([%w_]+)%s*:%s*(.-)%s*$')
            if key == 'IndentWidth' then
                settings.indent_width = tonumber(value)
            elseif key == 'TabWidth' then
                settings.tab_width = tonumber(value)
            elseif key == 'UseTab' then
                settings.use_tab = value:gsub('^"|"$', '')
            end
        end
    end

    return settings
end

local function apply_clang_format_indent(bufnr)
    if not clang_format_filetypes[vim.bo[bufnr].filetype] then
        return
    end

    local file_path = vim.api.nvim_buf_get_name(bufnr)
    if file_path == '' then
        return
    end

    local clang_format = find_clang_format(vim.fs.dirname(file_path))
    if clang_format == nil then
        return
    end

    local settings = parse_clang_format(clang_format)
    local indent_width = settings.indent_width or settings.tab_width

    if indent_width ~= nil then
        vim.bo[bufnr].shiftwidth = indent_width
        vim.bo[bufnr].softtabstop = indent_width
    end

    if settings.tab_width ~= nil then
        vim.bo[bufnr].tabstop = settings.tab_width
    elseif indent_width ~= nil then
        vim.bo[bufnr].tabstop = indent_width
    end

    if settings.use_tab == 'Never' or settings.use_tab == 'AlignWithSpaces' then
        vim.bo[bufnr].expandtab = true
    elseif settings.use_tab == 'Always' or settings.use_tab == 'ForIndentation' then
        vim.bo[bufnr].expandtab = false
    end
end

local group = vim.api.nvim_create_augroup('ClangFormatIndent', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = { 'c', 'cpp', 'objc', 'objcpp', 'h' },
    callback = function(args)
        apply_clang_format_indent(args.buf)
    end,
})
