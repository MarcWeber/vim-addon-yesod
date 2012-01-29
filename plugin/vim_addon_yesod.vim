" exec vam#DefineAndBind('s:c','g:addon_yesod','{}')
if !exists('g:addon_yesod') | let g:addon_yesod = {} | endif | let s:c = g:addon_yesod

call actions#AddAction('run yesod using cabal-ghci', {'action': funcref#Function('vim_addon_yesod#Restart')})

command -nargs=* Yesod call vim_addon_yesod#Restart()
command -nargs=* YesodStop call vim_addon_yesod#Stop()
