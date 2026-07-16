return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require('config.navigation.toggleterm').setup()
  end,
}
