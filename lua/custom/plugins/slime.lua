-- vim-slime: send code to a live REPL. Replaces iron.nvim.
--
-- Target is nvim's own :terminal, deliberately NOT zellij: nvim runs on the
-- compute node (salloc -> ssh -> nvim) while the zellij session lives on the
-- login node, so a zellij target would send code to the wrong machine.
-- :terminal spawns the REPL wherever nvim itself is running.
--
-- Output lands in the REPL split, not in the buffer. For plots inline in the
-- buffer, use molten (<leader>j...) instead.

return {
  {
    'jpalardy/vim-slime',
    ft = { 'python', 'sh', 'lua' },
    init = function()
      vim.g.slime_target = 'neovim'
      vim.g.slime_no_mappings = 1
      vim.g.slime_cell_delimiter = '# %%' -- same delimiter notebook.py uses
      -- Without this, ipython's autoindent mangles indented blocks on paste.
      vim.g.slime_bracketed_paste = 1
    end,
    config = function()
      -- Open a REPL beside the current buffer and wire slime to it in one step,
      -- so you never have to answer :SlimeConfig's jobid prompt by hand.
      vim.api.nvim_create_user_command('Repl', function()
        local srcwin = vim.api.nvim_get_current_win()
        local srcbuf = vim.api.nvim_get_current_buf()
        local cmd = vim.fn.filereadable '.venv/bin/ipython' == 1 and './.venv/bin/ipython'
          or (vim.fn.executable 'ipython' == 1 and 'ipython' or 'python3')
        vim.cmd('vsplit | terminal ' .. cmd)
        local jobid = vim.b.terminal_job_id
        vim.api.nvim_buf_set_var(srcbuf, 'slime_config', { jobid = jobid })
        vim.api.nvim_set_current_win(srcwin)
        vim.notify('REPL: ' .. cmd .. ' (jobid ' .. tostring(jobid) .. ')')
      end, { desc = 'Open a REPL split and attach slime to it' })
    end,
    -- <leader>c for "code". <leader>j is molten, <leader>s is telescope.
    keys = {
      { '<leader>cr', '<cmd>Repl<cr>', desc = 'Slime: open [r]epl and attach' },
      { '<leader>cc', '<Plug>SlimeSendCell', desc = 'Slime: send [c]ell (# %%)' },
      { '<leader>cs', '<Plug>SlimeParagraphSend', desc = 'Slime: [s]end paragraph' },
      { '<leader>cl', '<Plug>SlimeLineSend', desc = 'Slime: send [l]ine' },
      { '<leader>cs', '<Plug>SlimeRegionSend', mode = 'v', desc = 'Slime: [s]end selection' },
      { '<leader>cv', '<Plug>SlimeConfig', desc = 'Slime: config (pick target manually)' },
    },
  },
}
