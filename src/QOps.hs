{-# LANGUAGE        ScopedTypeVariables                   #-}
{-# LANGUAGE        LiberalTypeSynonyms                   #-}
{-# LANGUAGE        StandaloneDeriving                    #-}
{-# LANGUAGE        NoImplicitPrelude                     #-}
{-# LANGUAGE        FlexibleInstances                     #-}
{-# LANGUAGE        OverloadedLists                       #-}
{-# LANGUAGE        ConstraintKinds                       #-}
{-# LANGUAGE        BlockArguments                        #-}
{-# LANGUAGE        TypeOperators                         #-}
{-# LANGUAGE        TypeFamilies                          #-}
{-# LANGUAGE        DerivingVia                           #-}
{-# LANGUAGE        Rank2Types                            #-}
{-# LANGUAGE        PolyKinds                             #-}
{-# LANGUAGE        DataKinds                             #-}
{-# LANGUAGE        GADTs                                 #-}
{-# OPTIONS_GHC     -fplugin GHC.TypeLits.KnownNat.Solver #-}
{-# OPTIONS_HADDOCK not-home                              #-}

module QOps where

import Numeric.LinearAlgebra.Static as V hiding ( outer )
import Numeric.LinearAlgebra ( flatten, outer, kronecker, ident, toList )
import qualified Numeric.LinearAlgebra as LA ( (><) )
import GHC.TypeLits ( Nat, type (+), type (^),  KnownNat, natVal )
import qualified Data.Bit as B ( Bit(..) )
import Data.Proxy ( Proxy(..) )
import Prelude
import Control.Monad.Random as Rand
import QData

-- | Constructs new qubits
new :: Bit 1 -> QBit 1
new (0 ::: NoBit) = Q $ V.vector [ 1
                                 , 0 ]

new (1 ::: NoBit) = Q $ V.vector [ 0
                                 , 1 ]

-- | Collapses a qubit state (of size 1) to a single bit
measure :: QBit n -> Bit n
measure = undefined

measureN :: QBit 1 -> IO (Bit 1)
measureN = evalRandIO 
        . Rand.fromList 
        . zip [0,1] 
        . map (toRational . (^2)) 
        . toList 
        . extract 
        . getState

measureLA :: QBit 1 -> IO (Bit 1)
measureLA (Q q) = (evalRandIO 
               . Rand.fromList 
               . zip [0,1] 
               . map toRational) 
               [prob  (V.vector [1,0]), prob (V.vector [0,1])]
    where projOp b = V.mul (V.col b) (V.row b)
          prob b = ((^2) . V.norm_0) $ V.mul (projOp b) (V.col q)