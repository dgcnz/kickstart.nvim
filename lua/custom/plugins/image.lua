-- Inline images in the terminal, via the kitty graphics protocol.
-- Needs a terminal that speaks it (kitty, ghostty) -- Alacritty does not.
-- zellij >= 0.45 passes the protocol through.

local uv = vim.uv or vim.loop

-- Obsidian embeds are vault-root relative ("Files/foo.png"), not note relative,
-- and wikilinks carry a display width after a pipe ("foo.png|300").
local function resolve(document_path, image_path, fallback)
  if image_path:match '^https?://' or image_path:match '^data:' then
    return fallback and fallback(document_path, image_path) or image_path
  end

  local path = image_path:gsub('|.*$', '')
  path = path:gsub('%%(%x%x)', function(h)
    return string.char(tonumber(h, 16))
  end)

  local function exists(p)
    local stat = uv.fs_stat(p)
    return stat and stat.type == 'file'
  end

  if path:sub(1, 1) == '/' then
    return exists(path) and path or (fallback and fallback(document_path, image_path))
  end

  local dir = vim.fn.fnamemodify(document_path, ':h')

  -- 1. relative to the note itself
  local candidate = dir .. '/' .. path
  if exists(candidate) then
    return candidate
  end

  -- 2. relative to the vault root (nearest ancestor holding .obsidian)
  local root = vim.fs.root(document_path, { '.obsidian', '.git' })
  if root then
    candidate = root .. '/' .. path
    if exists(candidate) then
      return candidate
    end
    -- 3. bare filename, as Obsidian's attachment folder stores it
    candidate = root .. '/Files/' .. vim.fn.fnamemodify(path, ':t')
    if exists(candidate) then
      return candidate
    end
  end

  return fallback and fallback(document_path, image_path) or nil
end

---@module 'lazy'
---@type LazySpec
return {
  '3rd/image.nvim',
  build = false, -- skip luarocks; magick_cli below shells out to imagemagick
  ft = { 'markdown', 'vimwiki' },
  opts = {
    processor = 'magick_cli',
    backend = 'kitty',
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = true,
        download_remote_images = false,
        only_render_image_at_cursor = true,
        filetypes = { 'markdown', 'vimwiki' },
        resolve_image_path = resolve,
      },
    },
    max_width_window_percentage = 40,
    window_overlap_clear_enabled = true,
    editor_only_render_when_focused = true,
    tmux_show_only_in_active_window = true,
  },
}
