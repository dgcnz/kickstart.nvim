-- Inline image rendering in the terminal (3rd/image.nvim).
--
-- Nothing drives this on its own: image.nvim only draws when an integration
-- asks it to. See `integrations` below.

-- ImageMagick lives behind an lmod module on this cluster, but the binary is
-- RPATH-linked, so putting it on PATH is enough -- no `module load` required.
local MAGICK_BIN =
  '/sw/rev/25.04/rome_mofed_cuda80_rocky8/linux-rocky8-zen/gcc-8.5.0/imagemagick-7.1.1-39-o2sod7chb4phkvblh2usd6zwqnzvooaj/bin'

return {
  {
    '3rd/image.nvim',
    build = false,
    opts = {
      backend = 'kitty',
      processor = 'magick_cli', -- avoids needing the luarocks magick rock
      integrations = {}, -- nothing drives rendering yet; see the header
      -- max_width/max_height must be set: large images can otherwise crash the terminal.
      max_width = 100,
      max_height = 12,
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', '' },
    },
    init = function()
      if vim.fn.isdirectory(MAGICK_BIN) == 1 and not vim.env.PATH:find(MAGICK_BIN, 1, true) then
        vim.env.PATH = MAGICK_BIN .. ':' .. vim.env.PATH
      end
    end,
  },
}
