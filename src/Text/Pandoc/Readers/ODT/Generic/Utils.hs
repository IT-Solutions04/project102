{-# LANGUAGE ViewPatterns  #-}
{- |
   Module      : Text.Pandoc.Reader.ODT.Generic.Utils
   Copyright   : Copyright (C) 2015 Martin Linnemann
   License     : GNU GPL, version 2 or above

   Maintainer  : Martin Linnemann <theCodingMarlin@googlemail.com>
   Stability   : alpha
   Portability : portable

General utility functions for the odt reader.
-}

module Text.Pandoc.Readers.ODT.Generic.Utils
( uncurry3
, uncurry4
, uncurry5
, uncurry6
, swap
, reverseComposition
, tryToRead
, Lookupable(..)
, readLookupable
, readPercent
, findBy
, swing
, composition
) where

import Control.Category (Category, (<<<), (>>>))
import qualified Control.Category as Cat (id)
import Data.Char (isSpace)
import qualified Data.Foldable as F (Foldable, foldr)
import Data.Maybe
import Data.Text (Text)
import qualified Data.Text as T

-- | Equivalent to
-- > foldr (.) id
-- where '(.)' are 'id' are the ones from "Control.Category"
-- and 'foldr' is the one from "Data.Foldable".
-- The noun-form was chosen to be consistent with 'sum', 'product' etc
-- based on the discussion at
-- <https://groups.google.com/forum/#!topic/haskell-cafe/VkOZM1zaHOI>
-- (that I was not part of)
composition        :: (Category cat, F.Foldable f) => f (cat a a) -> cat a a
composition        = F.foldr (<<<) Cat.id

-- | Equivalent to
-- > foldr (flip (.)) id
-- where '(.)' are 'id' are the ones from "Control.Category"
-- and 'foldr' is the one from "Data.Foldable".
-- A reversed version of 'composition'.
reverseComposition :: (Category cat, F.Foldable f) => f (cat a a) -> cat a a
reverseComposition = F.foldr (>>>) Cat.id

-- | This function often makes it possible to switch values with the functions
-- that are applied to them.
--
-- Examples:
-- > swing map :: [a -> b] -> a -> [b]
-- > swing any :: [a -> Bool] -> a -> Bool
-- > swing foldr :: b -> a -> [a -> b -> b] -> b
-- > swing scanr :: c -> a -> [a -> c -> c] -> c
-- > swing zipWith :: [a -> b -> c] -> a -> [b] -> [c]
-- > swing find :: [a -> Bool] -> a -> Maybe (a -> Bool)
--
-- Stolen from <https://wiki.haskell.org/Pointfree>
swing :: (((a -> b) -> b) -> c -> d) -> c -> a -> d
swing = flip.(.flip id)
-- swing f c a = f ($ a) c


-- | Alternative to 'read'/'reads'. The former of these throws errors
-- (nobody wants that) while the latter returns "to much" for simple purposes.
-- This function instead applies 'reads' and returns the first match (if any)
-- in a 'Maybe'.
tryToRead :: (Read r) => Text -> Maybe r
tryToRead = (reads . T.unpack) >>> listToMaybe >>> fmap fst

-- | A version of 'reads' that requires a '%' sign after the number
readPercent :: ReadS Int
readPercent s = [ (i,s') | (i   , r ) <- reads s
                         , ("%" , s') <- lex   r
              ]

-- | Data that can be looked up.
-- This is mostly a utility to read data with kind *.
class Lookupable a where
  lookupTable :: [(Text, a)]

-- | Very similar to a simple 'lookup' in the 'lookupTable', but with a lexer.
readLookupable :: (Lookupable a) => Text -> Maybe a
readLookupable s =
  lookup (T.takeWhile (not . isSpace) $ T.dropWhile isSpace s) lookupTable

uncurry3 :: (a->b->c                -> z) -> (a,b,c          ) -> z
uncurry4 :: (a->b->c->d             -> z) -> (a,b,c,d        ) -> z
uncurry5 :: (a->b->c->d->e          -> z) -> (a,b,c,d,e      ) -> z
uncurry6 :: (a->b->c->d->e->f       -> z) -> (a,b,c,d,e,f    ) -> z

uncurry3 fun (a,b,c          ) = fun a b c
uncurry4 fun (a,b,c,d        ) = fun a b c d
uncurry5 fun (a,b,c,d,e      ) = fun a b c d e
uncurry6 fun (a,b,c,d,e,f    ) = fun a b c d e f

swap :: (a,b) -> (b,a)
swap (a,b) = (b,a)

-- | A version of "Data.List.find" that uses a converter to a Maybe instance.
-- The returned value is the first which the converter returns in a 'Just'
-- wrapper.
findBy :: (a -> Maybe b) -> [a] -> Maybe b
findBy _               []   = Nothing
findBy f ((f -> Just x):_ ) = Just x
findBy f (            _:xs) = findBy f xs
