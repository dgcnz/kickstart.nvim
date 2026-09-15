-- vim-slime: send code to a live REPL. Replaces iron.nvim.
--
-- Target adapts to where nvim is running:
--   * inside zellij  -> "zellij", REPL is a real pane to the right
--   * otherwise      -> "neovim", REPL is an nvim :terminal split
--
-- On the cluster the point of running zellij *on the compute node* is
-- detach/reattach: an ssh drop then leaves nvim and the REPL alive for as long
-- as the allocation lasts.
--
--   salloc --no-shell -p grete:interactive -A eckerlab -G 1g.10gb -t 02:00:00 --qos=2h
--   ssh <node>
--   zellij attach -c work        # zellij ON the node, not the login node
--   nvim notebook.py             # <leader>cr, then <leader>cc
--
-- Output lands in the REPL pane, not the buffer. Plots drawn by the REPL are
-- rendered by the terminal itself (kitty graphics), not by nvim.

local in_zellij = vim.env.ZELLIJ ~= nil and vim.env.ZELLIJ ~= ''

return {
  {
    'jpalardy/vim-slime',
    ft = { 'python', 'sh', 'lua' },
    init = function()
      vim.g.slime_no_mappings = 1
      vim.g.slime_cell_delimiter = '# %%' -- same delimiter notebook.py uses
      vim.g.slime_dont_ask_default = 1

      if in_zellij then
        vim.g.slime_target = 'zellij'
        vim.g.slime_default_config = { session_id = 'current', relative_pane = 'right' }
        -- vim-slime's zellij docs warn bracketed paste can misbehave with
        -- ipython; if pasted blocks come out mangled, flip this to 1.
        vim.g.slime_bracketed_paste = 0
      else
        vim.g.slime_target = 'neovim'
        -- Needed here, or ipython's autoindent mangles indented blocks.
        vim.g.slime_bracketed_paste = 1
      end
    end,
    config = function()
      local function repl_cmd()
        -- Absolute: a new zellij pane does not necessarily inherit nvim's cwd.
        if vim.fn.filereadable '.venv/bin/ipython' == 1 then
          return vim.fn.fnamemodify('.venv/bin/ipython', ':p')
        end
        return vim.fn.executable 'ipython' == 1 and 'ipython' or 'python3'
      end

      vim.api.nvim_create_user_command('Repl', function()
        local cmd = repl_cmd()
        if in_zellij then
          -- Spawn a real zellij pane; slime already points at "right".
          local args = { 'zellij', 'action', 'new-pane', '--direction', 'right', '--cwd', vim.fn.getcwd(), '--', cmd }
          vim.system(args, {}, function(r)
            vim.schedule(function()
              if r.code == 0 then
                vim.notify('REPL pane (zellij): ' .. cmd)
              else
                vim.notify('zellij new-pane failed: ' .. (r.stderr or ''), vim.log.levels.ERROR)
              end
            end)
          end)
        else
          local srcwin = vim.api.nvim_get_current_win()
          local srcbuf = vim.api.nvim_get_current_buf()
          vim.cmd('vsplit | terminal ' .. cmd)
          vim.api.nvim_buf_set_var(srcbuf, 'slime_config', { jobid = vim.b.terminal_job_id })
          vim.api.nvim_set_current_win(srcwin)
          vim.notify('REPL split (:terminal): ' .. cmd)
        end
      end, { desc = 'Open a REPL beside this buffer and attach slime to it' })
    end,
    -- <leader>c for "code". <leader>s is telescope.
    keys = {
      { '<leader>cr', '<cmd>Repl<cr>', desc = 'Slime: open [r]epl and attach' },
      { '<leader>cc', '<Plug>SlimeSendCell', desc = 'Slime: send [c]ell (# %%)' },
      { '<leader>cs', '<Plug>SlimeParagraphSend', desc = 'Slime: [s]end paragraph' },
      { '<leader>cl', '<Plug>SlimeLineSend', desc = 'Slime: send [l]ine' },
      { '<leader>cs', '<Plug>SlimeRegionSend', mode = 'v', desc = 'Slime: [s]end selection' },
      { '<leader>cv', '<Plug>SlimeConfig', desc = 'Slime: reconfigure target' },
    },
  },
}
