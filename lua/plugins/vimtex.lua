return {
  'lervag/vimtex',
  lazy = false, -- we don't want to lazy load VimTeX
  init = function()
    -- VimTeX configuration goes here, e.g.
    vim.g.vimtex_view_method = 'zathura'
    vim.g.vimtex_compiler_latexmk = {
      out_dir = './build',
      options = {
        '-outdir=./build', -- Tells latexmk to output files in the build directory
      },
    }
  end,
}
