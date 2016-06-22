{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeOperators       #-}

module Test.Issues.Issue137 (test_issue137)
  where

import Config
import Test.Framework
import Test.Framework.Providers.HUnit

import Prelude                                                  as P
import Data.Array.Accelerate                                    as A
import Data.Array.Accelerate.Examples.Internal                  as A


test_issue137 :: Backend -> Config -> Test
test_issue137 backend _conf =
  testCase "137" (assertEqual ref1 $ run backend test1)


ref1 :: Vector (Int,Int)
ref1 = fromList (Z:.384) [(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,1),(2,3),(0,1),(3,4),(0,1),(4,5),(0,1),(5,5),(0,1),(4,5),(0,1),(3,4),(0,1),(2,3),(0,1),(1,2),(1,2),(0,10000),(10000,10000),(10000,10000),(10000,10000),(10000,10000),(10000,10000),(10000,10000),(10000,10000),(10000,10000)]

test1 :: Acc (Vector (Int,Int))
test1 =
  let
      sz          = 3000 :: Int
      interm_arrA = use $ A.fromList (Z :. sz) [ P.fromIntegral $ 8 - (a `mod` 17) | a <- [1..sz]]
      msA         = use $ A.fromList (Z :. sz) [ P.fromIntegral $ (a `div` 8) | a <- [1..sz]]
      inf         = 10000 :: Exp Int
      infsA       = A.generate (index1 (384 :: Exp Int)) (\_ -> lift (inf,inf))
      inpA        = A.map (\v -> lift (abs v,inf) :: Exp (Int,Int)) interm_arrA
  in
  A.permute (\a12 b12 -> let (a1,a2) = unlift a12
                             (b1,b2) = unlift b12
                         in (a1 <=* b1)
                          ? ( lift (a1, A.min a2 b1)
                            , lift (b1, A.min b2 a1)
                            ))
            infsA
            (\ix -> index1 (msA A.! ix))
            inpA

