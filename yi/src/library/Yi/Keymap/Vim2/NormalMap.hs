module Yi.Keymap.Vim2.NormalMap
  ( defNormalMap
  ) where

import Yi.Prelude
import Prelude ()

import Data.Char

import Yi.Buffer hiding (Insert)
import Yi.Core (quitEditor)
import Yi.Editor
import Yi.Event
import Yi.Keymap.Keys
import Yi.Keymap.Vim2.Common
import Yi.Keymap.Vim2.Utils

mkDigitBinding :: Char -> (Event, EditorM (), VimState -> VimState)
mkDigitBinding c = (char c, return (), mutate)
    where mutate (VimState m Nothing) = VimState m (Just d)
          mutate (VimState m (Just count)) = VimState m (Just $ count * 10 + d)
          d = ord c - ord '0'

defNormalMap :: [VimBinding]
defNormalMap = [mkBindingY Normal (spec (KFun 10), quitEditor, id)] ++ pureBindings

pureBindings :: [VimBinding]
pureBindings =
    [zeroBinding] ++
    fmap (mkBindingE Normal) (
        [ (char 'h', vimMoveE (VMChar Backward), resetCount)
        , (char 'l', vimMoveE (VMChar Forward), resetCount)
        , (char 'j', vimMoveE (VMLine Forward), resetCount)
        , (char 'k', vimMoveE (VMLine Backward), resetCount)

        -- Word motions
        , (char 'w', vimMoveE (VMWordStart Forward), resetCount)
        , (char 'b', vimMoveE (VMWordStart Backward), resetCount)
        , (char 'e', vimMoveE (VMWordEnd Forward), resetCount)

        -- Intraline stuff
        , (char '$', vimMoveE VMEOL, resetCount)
        , (char '^', vimMoveE VMNonEmptySOL, resetCount)

        , (char 'i', return (), switchMode Insert)
        , (spec KEsc, return (), resetCount)
        ]
        ++ fmap mkDigitBinding ['1' .. '9']
    )

zeroBinding :: VimBinding
zeroBinding = VimBindingE prereq action
    where prereq ev _ = ev == char '0'
          action = do
              currentState <- getDynamic
              case (vsCount currentState) of
                  Just c -> setDynamic $ currentState { vsCount = Just (10 * c) }
                  Nothing -> do
                      vimMoveE VMSOL
                      setDynamic $ resetCount currentState
