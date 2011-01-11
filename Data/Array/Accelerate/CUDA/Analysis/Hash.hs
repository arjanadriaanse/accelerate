{-# LANGUAGE CPP, GADTs #-}
-- |
-- Module      : Data.Array.Accelerate.CUDA.Analysis.Hash
-- Copyright   : [2008..2010] Manuel M T Chakravarty, Gabriele Keller, Sean Lee, Trevor L. McDonell
-- License     : BSD3
--
-- Maintainer  : Manuel M T Chakravarty <chak@cse.unsw.edu.au>
-- Stability   : experimental
-- Portability : non-partable (GHC extensions)
--

module Data.Array.Accelerate.CUDA.Analysis.Hash (accToKey)
  where

import Data.Char
import Language.C
import Text.PrettyPrint
import Codec.Compression.Zlib
import Data.ByteString.Lazy.Char8                       (ByteString)
import qualified Data.ByteString.Lazy.Char8             as L

import Data.Array.Accelerate.AST
import Data.Array.Accelerate.Type
import Data.Array.Accelerate.Pretty ()
import Data.Array.Accelerate.Analysis.Type
import Data.Array.Accelerate.Analysis.Shape
import Data.Array.Accelerate.CUDA.CodeGen
import Data.Array.Accelerate.Array.Representation
import qualified Data.Array.Accelerate.Array.Sugar      as Sugar

#include "accelerate.h"


-- | Generate a unique key for each kernel computation
--
accToKey :: OpenAcc aenv a -> ByteString
accToKey acc =
  let key = compress . L.pack $ showAcc acc
  in  L.head key `seq` key


-- The first radical identifies the skeleton type (actually, this is arithmetic
-- sequence A000978), followed by the salient features that parameterise
-- skeleton instantiation.
--
showAcc :: OpenAcc aenv a -> String
showAcc (Generate e f)       = chr   1 : showExp e ++ showFun f
showAcc r@(Replicate s e a)  = chr   3 : showTy (accType a) ++ showExp e ++ showSI s e a r
showAcc r@(Index s a e)      = chr   5 : showTy (accType a) ++ showExp e ++ showSI s e r a
showAcc (Map f a)            = chr   7 : showTy (accType a) ++ showFun f
showAcc (ZipWith f x y)      = chr  11 : showTy (accType x) ++ showTy (accType y) ++ showFun f
showAcc (Fold f e a)         = chr  13 : chr (accDim a) : showTy (accType a) ++ showFun f ++ showExp e
showAcc (Fold1 f a)          = chr  17 : chr (accDim a) : showTy (accType a) ++ showFun f
showAcc (FoldSeg f e a _)    = chr  19 : chr (accDim a) : showTy (accType a) ++ showFun f ++ showExp e
showAcc (Fold1Seg f a _)     = chr  23 : chr (accDim a) : showTy (accType a) ++ showFun f
showAcc (Scanl f e a)        = chr  31 : showTy (accType a) ++ showFun f ++ showExp e
showAcc (Scanl' f e a)       = chr  43 : showTy (accType a) ++ showFun f ++ showExp e
showAcc (Scanl1 f a)         = chr  61 : showTy (accType a) ++ showFun f
showAcc (Scanr f e a)        = chr  79 : showTy (accType a) ++ showFun f ++ showExp e
showAcc (Scanr' f e a)       = chr 101 : showTy (accType a) ++ showFun f ++ showExp e
showAcc (Scanr1 f a)         = chr 127 : showTy (accType a) ++ showFun f
showAcc (Permute c _ p a)    = chr 167 : showTy (accType a) ++ showFun c ++ showFun p
showAcc (Backpermute _ p a)  = chr 191 : showTy (accType a) ++ showFun p
showAcc (Stencil f _ a)      = chr 199 : showTy (accType a) ++ showFun f
showAcc (Stencil2 f _ x _ y) = chr 313 : showTy (accType x) ++ showTy (accType y) ++ showFun f
showAcc x =
  INTERNAL_ERROR(error) "accToKey"
  (unlines ["incomplete patterns for key generation", render (nest 2 doc)])
  where
    acc = show x
    doc | length acc <= 250 = text acc
        | otherwise         = text (take 250 acc) <+> text "... {truncated}"

showTy :: TupleType a -> String
showTy UnitTuple = []
showTy (SingleTuple ty) = show ty
showTy (PairTuple a b)  = showTy a ++ showTy b

showFun :: OpenFun env aenv a -> String
showFun f = render . hcat . map pretty . fst $ runCodeGen (codeGenFun f)

showExp :: OpenExp env aenv a -> String
showExp e = render . hcat . map pretty . fst $ runCodeGen (codeGenExp e)

showSI :: SliceIndex (Sugar.EltRepr slix) (Sugar.EltRepr sl) co (Sugar.EltRepr dim)
       -> Exp aenv slix                         {- dummy -}
       -> OpenAcc aenv (Sugar.Array sl e)       {- dummy -}
       -> OpenAcc aenv (Sugar.Array dim e)      {- dummy -}
       -> String
showSI sl _ _ _ = slice sl 0
  where
    slice :: SliceIndex slix sl co dim -> Int -> String
    slice (SliceNil)            _ = []
    slice (SliceAll   sliceIdx) n = '_'    :  slice sliceIdx n
    slice (SliceFixed sliceIdx) n = show n ++ slice sliceIdx (n+1)

{-
-- hash function from the dragon book pp437; assumes 7 bit characters and needs
-- the (nearly) full range of values guaranteed for `Int' by the Haskell
-- language definition; can handle 8 bit characters provided we have 29 bit for
-- the `Int's without sign
--
quad :: String -> Int32
quad (c1:c2:c3:c4:s)  = (( ord' c4 * bits21
                         + ord' c3 * bits14
                         + ord' c2 * bits7
                         + ord' c1)
                         `mod` bits28)
                        + (quad s `mod` bits28)
quad (c1:c2:c3:[]  )  = ord' c3 * bits14 + ord' c2 * bits7 + ord' c1
quad (c1:c2:[]     )  = ord' c2 * bits7  + ord' c1
quad (c1:[]        )  = ord' c1
quad ([]           )  = 0

ord' :: Char -> Int32
ord' = fromIntegral . ord

bits7, bits14, bits21, bits28 :: Int32
bits7  = 2^(7 ::Int32)
bits14 = 2^(14::Int32)
bits21 = 2^(21::Int32)
bits28 = 2^(28::Int32)
-}
