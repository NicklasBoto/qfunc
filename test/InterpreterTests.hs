module InterpreterTests( 
    runTests,
) where
import Control.Monad.Except (runExceptT, liftIO)
import Interpreter.Run

runTests :: IO Bool
runTests = do
  -- runExceptT tar en exceptT-transformerad monad och kör den, tar ur den inre monaden ur exceptT
  -- och returnar Either left right
  res <- runExceptT (foldr runTest (pure 0) tests)
  case res of
    Left err -> putStrLn ("Interpreter test failed with error: " ++ show err) >> return False
    Right correct -> putStrLn ("Succesful tests for interpreter " ++ show correct ++ "/" ++ show (length tests)) >> return True

runTest :: (String, String) -> Run Int -> Run Int
runTest (fileName, expectedValue) b = do
  liftIO . print $ "Testing file " ++ show fileName
  res <- readfile (testPath fileName) >>= run
  acc <- b
  if show res == expectedValue
    then do
      return $ acc + 1
    else do
      liftIO $ putStrLn $ "Got " ++ show res ++ " but expected " ++ show expectedValue
      return acc

testPath :: String -> String
testPath testName = "test/interpreter-test-suite/" ++ testName

tests :: [(FilePath, String)]
tests =
  [ 
    ("cnot.fq", "0"),
    ("equals.fq", "1"),
    ("higher-order-function.fq","⟨0,1⟩"),
    ("id.fq", "1"),
    ("let-tup-q.fq", "0"),
    ("let-tup.fq", "0"),
    ("partial-app-cnot.fq", "1"),
    ("partial-app-comp.fq", "0"),
    ("partial-app-new.fq",  "1"),
    ("partial-app-meas.fq", "0"),
    ("pauliX.fq", "1"),
    ("pauliY.fq", "1"),
    ("pauliZ.fq", "0"),
    ("phase.fq", "0"),
    ("plus.fq", "0"),
    ("second-q.fq", "0"),
    ("second.fq", "1"),
    ("seventh.fq", "0"),
    ("swap.fq", "1"),
    ("swapTwice.fq", "1"),
    ("third.fq", "1"),
    ("teleport.fq", "1"),
    ("nested-let.fq", "0"),
    ("deutsch.fq", "1"),
    ("qft5.fq",     "⟨1,⟨0,⟨1,⟨0,1⟩⟩⟩⟩"),
    ("qft4.fq",     "⟨0,⟨1,⟨0,1⟩⟩⟩"),
    ("qft3.fq",     "⟨0,⟨1,0⟩⟩"),
    ("qft2.fq",     "⟨0,1⟩"),
    ("qft1.fq",     "0"),
    ("tdagger.fq",  "1")
  ]

