# Shared info (specifc info below)
This information is both in the
[nvimClipboardSyncDaemonCpp](https://github.com/SebastianMusic/nvimClipboardSyncDaemonCpp)
readme and also in the
[nvimClipboardSyncPlugin](https://github.com/SebastianMusic/nvimClipboardSyncPlugin)
readme
The reason for this is that these to programs are tightly intertwined and are
meant to be used together so some shared information is useful
#### Why was this made
I made these programs since tmux-yank was not enough for my use case, reason
being it was slow having to make sure all the text you wanted to copy was
displayed in your terminal at the same time and it would also copy artifacts
from neovim i did not neccesarily want in my clipboard copy such as indenation
symbols and lsp errors.
#### High level overview of functionaility 
Daemons establish a tcp connection over an ssh reverse tunnel and each daemon
sets up a pipe to listen to and accept new neovim clients. that way each neovim
instance talks to its local daemon and the daemon only forwards to other
daemons.
When everything is up and running you will simply open neovim and yank and it
will be transffered for you.

# NvimClipboardSync Specific info
This plugin is a companion plugin to the [daemon](https://github.com/SebastianMusic/nvimClipboardSyncDaemonCpp) this plugin forwards all yanked text to your local running [daemon](https://github.com/SebastianMusic/nvimClipboardSyncDaemonCpp) and reads from this daemon as well and sets the `"0` register to that which is read from the daemon.
# Installation
#### Lazy nvim
You can copy the following configuration
```lua
return {
  'sebastianmusic/nvimClipboardSyncPlugin',
  lazy = false,
  config = function()
    require('nvimClipboardSync').setup { debug = true }
  end,
}
```

### how to use
The nvim plugin is fairly straightforward simply start neovim and start yanking.
if its not working its likely it is something with the [daemon](https://github.com/SebastianMusic/nvimClipboardSyncDaemonCpp)

# TODOS
- Currently there is no issue with the setting of registers but there might be
bugs for very large registers this must be investigated



