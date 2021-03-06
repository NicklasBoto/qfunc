module GatesTests (
    runTests
) where

import TestCore
import Test.QuickCheck
import Test.QuickCheck.Monadic as TM
import Numeric.LinearAlgebra as LA

runTests :: IO Bool
runTests = do
    putStrLn "QuickCheck tests unmodified QState sums to 1"
    b_sumOne <- quickCheckResult prop_sumOne

    putStrLn "QuickCheck tests sum of QState = 1 after applying gates"
    b_sumG <- mapM (quickCheckResult . prop_gate_sum) [hadamard, cnot', pauliX, pauliY, pauliZ, urot 1, phasePi8, identity]

    putStrLn "QuickCheck tests that matrices are unitary"
    b_unit <- mapM (quickCheckResult . prop_unitary) [hmat, cmat, phasemat 3, pXmat, pYmat, pZmat, idmat] 

    a <- test_rev_gates
    putStrLn $ "Tests reversibility of gates on single qubits: " ++ show a

    b <- test_rev_cnot
    putStrLn $ "Tests reversibility of cnot with two qubits: " ++ show b

    return $ all isSuccess $ b_sumOne : b_unit ++ b_sumG


-- | Checks that the given matrix is unitary
prop_unitary :: Matrix C -> Property
prop_unitary mx = foldl (.&&.) isSquare [ isConjugate, innerHolds mx , normal ]
  where isSquare    = property $ rows mx == cols mx
        isConjugate = property $ (#=) (mx LA.<> conj mx) (ident (rows mx))
        normal      = property $ (#=) (conj mx LA.<> mx) (mx LA.<> conj mx)
        detIsOne    = property $ (~=) (abs (det mx)) 1

-- | Checks that the inner product holds during matrix transformations
innerHolds :: Matrix C -> Property
innerHolds mx = forAll genNs test
  where test bs = (~=) ((#>) mx (randV 0 bs) <.> (#>) mx (randV 1 bs)) (randV 0 bs <.> randV 1 bs)
        randV n bs = toColumns (ident (rows mx)) !! (bs !! n)
        genNs = vectorOf 2 (choose (0, rows mx - 1))


-- | Checks that the sum of the squared elements in the vector sums to 1 
prop_gate_sum :: (QBit -> QM QBit) -> QState -> Property
prop_gate_sum g q = TM.monadicIO $ do
    run' $ addState q
    (_,size) <- run' getState
    qbt <- run' $ getRandQbit size
    s <- run' $ applyGate' q g qbt
    let su = norm_2 $ state s
    TM.assert (su < 1.00001 && su > 0.9999) --due to rounding errors, cannot test == 1

-- Basic quickCheck test, that unmodified QState sums to 1
prop_sumOne :: QState -> Bool
prop_sumOne (QState v) = norm_2 v == 1

-- Test reversibility of gates 
-- | Given a gate that takes a single qbit, applies it and checks reversibility 
test_rev :: (QBit -> QM QBit) -> IO Bool
test_rev g = TestCore.run $ do
    qbt <- new 0
    (b,a) <- applyTwice qbt g
    let bf = map realPart (toList $ state b)
    let af = map realPart (toList $ state a)
    let cmp =  zipWith (\ x y -> abs (x - y)) bf af
    return $ all (<0.0000001) cmp -- cannot be checked directly due to rounding errors

-- All other gates than hadamard could be tested with (state a == state b)

-- | Applies the reversibility tests to all gates that matches type signature of QBit -> QM QBit.
test_rev_gates :: IO Bool
test_rev_gates = liftM and $ mapM test_rev gates
    where gates = [TestCore.phase, hadamard, pauliX, pauliY, pauliZ, phasePi8, identity]

-- | Test reversibility of cnot 
test_rev_cnot :: IO Bool
test_rev_cnot = TestCore.run $ do
    q1 <- new 1
    q2 <- new 0
    b <- get
    cnot (q1,q2) >>= cnot
    a <- get
    return (state a == state b)
