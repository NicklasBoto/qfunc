module QStateTests (
    runTests
) where

import TestCore
import Test.QuickCheck
import Test.QuickCheck.Monadic as TM
import Numeric.LinearAlgebra as LA

runTests :: IO Bool
runTests = do 
    putStrLn "QuickCheck tests qstate size keeps good norm after applying hadamard gate"
    b_h <- quickCheckResult $ prop_hadamard 8

    putStrLn "QuickCheck tests the norm of generated QStates, of 1 < lengths < n , is one"
    b_n <- quickCheckResult $ prop_norm 8

    return $ all isSuccess [b_n, b_h]

-- | Checks that the QState of arbitrary size after a hadamard gate is applied keeps a good norm and
-- that the QState vector only contains two amplitudes at 1/sqrt(2).
-- This function in particular may kill your computer if it's let to run without max bounds.
prop_hadamard :: Int -> Property
prop_hadamard n
  | n > maxAllowedN = errorWithoutStackTrace maxExceededErrorMsg
  | otherwise = monadicIO $ do
    m <- pick $ choose (1,n)
    TM.forAllM (genBits n) $ assertive m
      where assertive :: Int -> [Bit] -> PropertyM IO ()
            assertive m bs = do
              qs@(QState s) <- qrun $ mapM new bs >>= \x -> hadamard (x !! div (length bs-1) m) >> get
              assert $ goodNorm qs && length (filter ((1/sqrt 2) ~=) (toList s)) == 2

-- | Checks that the norm of generated QStates, of 1 < lengths < n , is one
prop_norm :: Int -> Property
prop_norm n
  | n > maxAllowedN = errorWithoutStackTrace maxExceededErrorMsg
  | otherwise = monadicIO $
  TM.forAllM (genBits n) assertive
  where assertive :: [Bit] -> PropertyM IO ()
        assertive bs = do
          qs <- qrun $ mapM_ new bs >> get
          assert $ goodNorm qs

-- | Maximum allowed length of QState
maxAllowedN :: Int
maxAllowedN = 10

-- | The error message returned when maxAllowedN is exceeded
maxExceededErrorMsg :: String
maxExceededErrorMsg = "your computer almost just died. either you forgot to input a value, or you want to raise the value for allowed inputs"

-- | Checks that the norm of the given QState is 1
goodNorm :: QState -> Bool
goodNorm (QState s) = (~=) (norm_2 s :+ 0) 1