-- Jupyter-style interactive execution, with plots drawn inline in the terminal.
--
-- Two environments are involved, on purpose (this is molten's documented layout):
--   * ~/.venvs/nvim  runs molten's own plugin code (pynvim + jupyter_client).
--                    It never runs your code.
--   * a kernelspec   runs your code. `flow` -> playground/flow_tutorial/.venv
--                    Register more with:
--                      uv pip install --python /path/to/.venv/bin/python ipykernel
--                      /path/to/.venv/bin/python -m ipykernel install --user --name NAME
--
-- Usage: :MoltenInit flow   (or :MoltenInit to pick from a list)
-- Kernels outlive nvim, so a long-running job survives closing the editor.

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
      integrations = {}, -- molten drives rendering; don't auto-render markdown
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

  {
    'benlubas/molten-nvim',
    version = '^1.0.0',
    dependencies = { '3rd/image.nvim' },
    -- NOTE: if molten's commands go missing after an update, lazy-loading can keep it
    -- off the runtimepath during registration. Fix with:
    --   :Lazy load molten-nvim  then  :UpdateRemotePlugins  then restart
    build = ':UpdateRemotePlugins',
    init = function()
      vim.g.python3_host_prog = vim.fn.expand '~/.venvs/nvim/bin/python'
      vim.g.molten_image_provider = 'image.nvim'
      vim.g.molten_output_win_max_height = 20
      -- Other options exist (virtual-text output, auto-open, wrapping);
      -- see `:h molten` before enabling, they interact with image rendering.
    end,
    config = function()
      -- Molten has no "run the whole notebook" command: MoltenReevaluateAll only
      -- re-runs cells it already knows about. This defines every `# %%` block as a
      -- cell and evaluates it, which is the "restart & run all" you actually want.
      vim.api.nvim_create_user_command('MoltenRunAll', function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local starts = {}
        for i, l in ipairs(lines) do
          if l:match '^#%s*%%%%' then
            table.insert(starts, i)
          end
        end
        if #starts == 0 then
          vim.notify('MoltenRunAll: no `# %%` cells in this buffer', vim.log.levels.WARN)
          return
        end
        for idx, s in ipairs(starts) do
          local e = (starts[idx + 1] or (#lines + 1)) - 1
          vim.fn.MoltenEvaluateRange(s, e)
        end
        vim.notify(('MoltenRunAll: queued %d cells'):format(#starts))
      end, { desc = 'Molten: evaluate every `# %%` cell in the buffer' })
    end,

    -- <leader>j for "jupyter". <leader>m is already taken by iron.nvim's marks.
    keys = {
      { '<leader>ji', '<cmd>MoltenInit<cr>', desc = 'Molten: [i]nit kernel' },
      { '<leader>ja', '<cmd>MoltenRunAll<cr>', desc = 'Molten: run [a]ll `# %%` cells' },
      { '<leader>jA', '<cmd>MoltenReevaluateAll<cr>', desc = 'Molten: re-evaluate [A]ll known cells' },
      { '<leader>je', '<cmd>MoltenEvaluateOperator<cr>', desc = 'Molten: [e]valuate operator' },
      { '<leader>jl', '<cmd>MoltenEvaluateLine<cr>', desc = 'Molten: evaluate [l]ine' },
      { '<leader>jr', '<cmd>MoltenReevaluateCell<cr>', desc = 'Molten: [r]e-evaluate cell' },
      { '<leader>jv', ':<C-u>MoltenEvaluateVisual<cr>gv', mode = 'v', desc = 'Molten: evaluate [v]isual' },
      { '<leader>jo', '<cmd>MoltenShowOutput<cr>', desc = 'Molten: show [o]utput' },
      { '<leader>jh', '<cmd>MoltenHideOutput<cr>', desc = 'Molten: [h]ide output' },
      { '<leader>jd', '<cmd>MoltenDelete<cr>', desc = 'Molten: [d]elete cell' },
      { '<leader>jb', '<cmd>MoltenOpenInBrowser<cr>', desc = 'Molten: open in [b]rowser' },
    },
  },
}
