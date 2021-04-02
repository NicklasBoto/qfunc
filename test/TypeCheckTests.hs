module TypeCheckTests where 
import Type.HM
import AST.AST
import Data.Either (lefts,rights)

--- Test that should be true

-- | Inferring 0 should be !Bit
testBit = inferExp "0" == Right (TypeDup TypeBit)
-- | The inside is (!Bit, !Bit) which makes ! move outside, to !(Bit, Bit)
testDupProd = inferExp "(0, 0)" == Right (TypeDup (TypeBit :>< TypeBit))

-- | Expected (?a, ?b) -o ?a
testFst = inferExp "\\x.let (a,b) = x in a" == Right ((TypeFlex "a" :>< TypeFlex "b") :=> TypeFlex "a")

-- | \x.x should have type ?a->?a, since it could be either linear or not linear.
testId = inferExp "\\x.x" == Right (TypeFlex "a" :=> TypeFlex "a")

-- | Test nested let statements
testNestTup = inferExp "\\x . let (a,b) = x in let (b,c) = b in (a,b,c)"  ==  Right (TypeFlex "a" :>< TypeFlex "b" :>< TypeFlex "c" :=> TypeFlex "a" :>< TypeFlex "b" :>< TypeFlex "c")

-- | Test that the output of a linear function cannot be made duplicable ??
testLinFunSub = null (lefts $ runtc $ "f : !(Bit -o Bit) " ++
                                      "f x = meas (new x) " ++
                                      "g : Bit " ++
                                      "g = f 0 ")

trueTests :: IO Bool 
trueTests = return $ testBit && testDupProd && testFst && testId && testNestTup && testLinFunSub

--- Test that should fail (throw an exception)

-- | (\x. let(a,b) = x in a) 0 should fail, since 0 is not a product type
testLetNoProd = inferExp "(\\x.let (a,b) = x in a) 0" == Left (SubtypeFailError (TypeFlex "c" :>< TypeFlex "d") (TypeDup TypeBit))

-- | "(\\x . if new 0 then x else x) 0" should fail, since new 0 is a qubit
testIfNoBit = inferExp "(\\x . if new 0 then x else x) 0" == Left (SubtypeFailError (TypeDup TypeBit) TypeQBit)

-- | Test that if statments with mismatching types of then else throws an error 
testMisMatchingIf = head (lefts $ runtc "q : QBit q = new 0 f : QBit f = if 1 then q else 0") == UnificationFailError TypeQBit (TypeDup TypeBit) 
-- | Test that it is not possible to create a duplicable qubit
testDupQbit = head (lefts $ runtc "q : !QBit q = new 0") == UnificationFailError (TypeDup TypeQBit) TypeQBit

-- | Test that a linear bit cannot be used in a nonlinear function
testLinBit = head $ lefts $ runtc $ "b : Bit b = 0 " 
                                 ++ "dup : !(Bit >< Bit) dup = (b,b)"

-- | Test that the output of a linear function cannot be made duplicable ??
testLinFun = head $ lefts $ runtc $ "f : Bit -o Bit " ++
                                    "f x = meas (new x) " ++
                                    "g : !Bit " ++
                                    "g = f 0 "

-- | Test linearity of single variable, should not be possible to have two references to a linear bit.
testLinRef = typecheck . run $ "b1 : Bit b1 = 0 " ++
                               "b2 : Bit b2 = b1 " ++ 
                               "b3 : Bit b3 = b1"

-- | Test a nonlinear function can be used many times. Should succeed.
testUseLinFun = typecheck . run $ "f : !(Bit -o Bit) f a = 0 " ++
                               "b2 : Bit b2 = f 1 " ++ 
                               "b3 : Bit b3 = f 1"

-- | Test a linear function can't be used twice. Should fail.
testUseLinFunTwice = typecheck . run $ "f : Bit -o Bit f a = 0 " ++
                                        "b2 : Bit b2 = f 1 " ++ 
                                        "b3 : Bit b3 = f 1"