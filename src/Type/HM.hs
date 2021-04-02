{-# LANGUAGE LambdaCase #-}

module Type.HM where

import AST.AST
import qualified Data.Map as Map
import qualified Data.Set as Set
import Control.Monad.State
import Control.Monad.Except
import Parser.Print
import Data.List (nub, intercalate)
import Data.Bifunctor (first)
import Debug.Trace


-- | Representations of free and bound variables in lambda abstractions
data Named
    = Free String
    | Bound Integer
    deriving (Eq, Ord, Show)

-- | A scheme has a type, together with a list of (Forall) bound type variables.
data Scheme = Forall [TVar] Type

-- | A type variable (TVar) is either a normal linear type variable (LVar) "a", 
--   or the more general flexible type variable (FVar) "?a".
data TVar
    = LVar String
    | FVar String
    deriving (Eq, Ord)

instance Show TVar where
    show (LVar a) = a
    show (FVar a) = '?' : a

instance Show Scheme where
    show (Forall [] t) = printTree (reverseType t)
    show (Forall vs t) = "∀ " ++ unwords (map show vs) ++ " . "
                      ++ printTree (reverseType t)

-- | Each variable in the TypeEnv has an associated type Scheme.
newtype TypeEnv = TypeEnv (Map.Map Named Scheme) deriving Show

-- | A substitution is a map from a type variable to the type it 
--  should be substituted with. It could be another type variable.
type Subst = Map.Map TVar Type

-- | The null substitution are the substitution where nothing are substituted.
nullSubst :: Subst
nullSubst = Map.empty

-- | The empty environment are the type environment where no variables exist.
emptyEnv :: TypeEnv
emptyEnv = TypeEnv Map.empty

-- | Type errors that can occur during type check.
data TypeError
    = NotInScopeError Named
    | InfiniteTypeError String Type
    | UnificationFailError Type Type
    | SubtypeFailError Type Type
    | ProductDuplicityError Type Type
    | LinearityError Term
    deriving Eq

instance Show TypeError where
    show (UnificationFailError (TypeDup (TypeVar _)) a) =
        "Expected duplicable type, got type '" ++ show a ++ "'"

    show (UnificationFailError e a) =
        "Couldn't match expected type '" ++ show e ++
        "' with actual type '" ++ show a ++ "'"

    show (SubtypeFailError l r) =
        "Type '" ++ show l ++ "' is not a subtype of type '" ++ show r ++ "'"

    show (NotInScopeError (Bound j)) =
        "The impossible happened, free deBruijn index"

    show (NotInScopeError (Free v)) =
        "Variable not in scope: " ++ v

    show (InfiniteTypeError v t) =
        "Occurs check: cannot construct the infinite type: " ++
        show v ++ " ~ " ++ show t

    show (ProductDuplicityError l r) =
        "Linear product operands must have equal duplicity: " ++ show l ++ " ⊗  " ++ show r

-- | Counter for creating fresh type variables
type Counter = Int

-- | The monad type inferrement occurs, it could have an exception
--   if there is a type error. It keeps track of a counter for what
--   the next fresh type variable should be.
type Infer = ExceptT TypeError (State Counter)

-- | Extend the type environment with a new bound variable together with its type scheme.
extend :: TypeEnv -> (Named, Scheme) -> TypeEnv
extend (TypeEnv env) (n,s) = TypeEnv $ Map.insert n s env

-- | Apply final substitution and normalize the type variables 
closeOver :: (Subst, Type) -> Scheme
closeOver (sub, ty) = normalize sc
  where sc = generalize emptyEnv (apply sub ty)

-- | 
normalize :: Scheme -> Scheme
normalize (Forall ts body) = Forall (fmap (LVar . snd) ord) (normtype body)
  where
    ord = zip (nub $ fv body) letters
    
    fv (TypeVar  a) = [a]
    fv (TypeFlex a) = [a]
    fv (a :=> b)    = fv a ++ fv b
    fv (a :>< b)    = fv a ++ fv b
    fv _            = []

    normtype (a :=> b) = normtype a :=> normtype b
    normtype (a :>< b) = normtype a :>< normtype b
    normtype (TypeVar a)   =
      case lookup a ord of
        Just x -> TypeVar x
        Nothing -> error "type variable not in signature"
    normtype (TypeFlex a) =
        case lookup a ord of
            Just x -> TypeFlex x
            Nothing -> error "type flexible not in signature"
    normtype a = a

-- | 
compose :: Subst -> Map.Map TVar Type -> Map.Map TVar Type
compose s1 s2 = Map.map (apply s1) s2 `Map.union` s1

(∘) :: Subst -> Map.Map TVar Type -> Map.Map TVar Type
(∘) = compose

-- | Make a type duplicable
bang :: Type -> Type
bang = TypeDup

-- | Make type non-duplicable
debang :: Type -> Type
debang (TypeDup a) = a
debang          a  = a

-- | Converts a type variable to a type flex 
flex :: Type -> Type
flex (TypeVar a) = TypeFlex a
flex          t  =          t

-- | Converts a type flex to a type variable
deflex :: Type -> Type
deflex (TypeFlex a) = TypeVar a
deflex           t  =         t

-- | Transforms all flex variables to normal linear type variables.
deflexType :: Type -> Type
deflexType (a :=> b) = deflexType a :=> deflexType b
deflexType (a :>< b) = deflexType a :>< deflexType b
deflexType (TypeDup a) = TypeDup $ deflexType a
deflexType a = deflex a

class Substitutable a where
    -- | Given a substitution and a type, if the type contains instances of type variables
    --   that also exist in the substitution map, it replaces those instances with the new
    --   ones in the map.
    apply :: Subst -> a -> a
    -- | Find all free type variables.
    ftv   :: a -> Set.Set TVar

instance Substitutable Type where
    -- | TypeVariables in the type are substituted if they exist in the substitution.
    apply _ TypeBit = TypeBit
    apply _ TypeQBit = TypeQBit
    apply _ TypeUnit = TypeUnit
    apply s (TypeDup d) = TypeDup $ apply s d
    apply s t@(TypeVar v) = Map.findWithDefault t (LVar v) s
    apply s t@(TypeFlex v) = Map.findWithDefault t (FVar v) s 
    apply s (t1 :=> t2) = apply s t1 :=> apply s t2
    apply s (t1 :>< t2) = apply s t1 :>< apply s t2

    -- | The free type variables for a type are all type variables in the type,
    --   since no type variables are bound.
    ftv (TypeVar v) = Set.singleton (LVar v)
    ftv (TypeFlex v) = Set.singleton (FVar v)
    ftv (t1 :=> t2) = Set.union (ftv t1) (ftv t2)
    ftv _constant   = Set.empty

instance Substitutable Scheme where
    -- | The type inside the scheme are applied to the substitution,
    --   with the bound type variables removed from the substitution.
    apply s (Forall as t) = Forall as $ apply s' t
        where s' = foldr Map.delete s as

    -- | All free type variables in a scheme is the type variables
    --   of the type, except for the ones that are bound by the Forall.
    ftv (Forall as t) = Set.difference (ftv t) (Set.fromList as)

instance Substitutable a => Substitutable [a] where
    apply = fmap . apply
    ftv = foldr (Set.union . ftv) Set.empty

instance Substitutable TypeEnv where
    apply s (TypeEnv env) = TypeEnv $ Map.map (apply s) env
    ftv (TypeEnv env) = ftv $ Map.elems env

occursCheck ::  Substitutable a => TVar -> a -> Bool
occursCheck a t = a `Set.member` ftv t

-- ?a ~  t : [?a/t]
--  t ~ ?a : [?a/t]
-- ?a ~ !t : [?a/!t]
-- ?a ~ ?b : [a/b]

-- | Tries to find common type for two input types
unify :: Type -> Type -> Infer Subst
unify (TypeDup (l :=> r)) (l' :=> r') = do
        s1 <- unify l l'
        s2 <- unify (apply s1 r) (apply s1 r')
        return (s2 ∘ s1)
unify (l :=> r) (l' :=> r') = do
        s1 <- unify l l'
        s2 <- unify (apply s1 r) (apply s1 r')
        return (s2 ∘ s1)
unify (TypeDup (l :>< r)) (l' :>< r') = do
    s1 <- unify (TypeDup l) l'
    s2 <- unify (TypeDup r) r'
    return (compose s2 s1)
unify (l :>< r) (TypeDup (l' :>< r')) = do
    s1 <- unify l (TypeDup l')
    s2 <- unify r (TypeDup r')
    return (compose s2 s1)
unify (l :>< r) (l' :>< r') = do
    s1 <- unify l l'
    s2 <- unify r r'
    return (compose s2 s1)
unify (TypeFlex a) (TypeFlex b) = bind (LVar a) (TypeVar b)
unify (TypeFlex a) (TypeDup  b) = bind (FVar a) (TypeDup b)
unify t (TypeFlex b) = bind (FVar b) t
unify (TypeFlex a) t = bind (FVar a) t
unify (TypeVar a) t =  bind (LVar a) t
unify t (TypeVar a) = bind (LVar a) t
unify (TypeDup a) (TypeDup b) = unify a b
unify t t' | t' <: t && isConstType t = return nullSubst
           | otherwise = throwError $ UnificationFailError t t'

-- | Binds a type variable with another type and returns a substitution.
bind :: TVar -> Type -> Infer Subst
bind a'@(LVar a) t | t == TypeVar a   = return nullSubst
                   | occursCheck a' t = throwError $ InfiniteTypeError a t
                   | otherwise        = return $ Map.singleton a' t
bind a'@(FVar a) t | t == TypeFlex a  = return nullSubst
                   | occursCheck a' t = throwError $ InfiniteTypeError a t
                   | otherwise        = return $ Map.singleton a' t

-- | Checks if a type is a constant type
isConstType :: Type -> Bool
isConstType TypeBit = True
isConstType TypeQBit = True
isConstType TypeUnit = True
isConstType (TypeDup d) = isConstType d
isConstType _type = False

-- | Introduce a new type variable.
--   Also updates the internal type variable counter to avoid collisions.
fresh :: Infer Type
fresh = do
  s <- get
  put (s+1)
  return $ TypeVar $ letters !! s

-- | Introduce a new flexible type variable.
freshFlex :: Infer Type
freshFlex = do
    s <- get
    put (s+1)
    return $ TypeFlex $ letters !! s

-- | Returns a list of strings used for fresh type variables.
letters :: [String]
letters = [1..] >>= flip replicateM ['a'..'z']

-- | Renames all TVars in the scheme and applies it
--   to get a type with unique (and free) type variables.
instantiate :: Scheme -> Infer Type
instantiate (Forall as t) = do
    as' <- mapM rename as -- Each bound variable gets a new name.
    let s = Map.fromList $ zip as as' -- Map from old type variables to new names.
    return $ apply s t

rename :: TVar -> Infer Type 
rename (FVar _) = freshFlex
rename (LVar _) = fresh

-- | 
generalize :: TypeEnv -> Type -> Scheme
generalize env t  = Forall as t
    where as = Set.toList $ ftv t `Set.difference` ftv env

-- | Infers a substitution and a type from a Term
infer :: Integer -> TypeEnv -> Term -> Infer (Subst, Type)
infer i env (Idx j)      = lookupEnv env (Bound (i-j-1))
infer i env (Fun var)   = lookupEnv env (Free var)
infer i env (Bit _)      = return (nullSubst, bang TypeBit)
infer i env (Gate gate)  = return (nullSubst, inferGate gate)
infer i env (Tup l r)  = do
    (ls, lt) <- infer i env l
    (rs, rt) <- infer i env r
    t <- productExponential lt rt
    return (ls ∘ rs, t)
infer i env (App l r) = do
    tv <- fresh
    (s1,t1) <- infer i env l
    (s2,t2) <- infer i (apply s1 env) r
    subtypeCheck t1 t2
    s3      <- unify (apply s2 t1) (t2 :=> tv)
    return (s3 ∘ s2 ∘ s1, apply s3 tv)
infer i env (IfEl b l r) = do
    (s1,t1) <- infer i env b
    (s2,t2) <- infer i env l
    (s3,t3) <- infer i env r
    s4 <- unify (TypeDup TypeBit) t1
    s5 <- unify t2 t3
    return (s5 ∘ s4 ∘ s3 ∘ s2 ∘ s1, apply s5 t2)
infer i env (Let eq inn) = do
    tv1 <- inferDuplicity (Abs inn) <$> fresh 
    tv2 <- inferDuplicity inn <$> fresh
    (seq, teq) <- infer i env eq 
    product <- unify teq (tv1 :>< tv2)
    let env' = env `extend` (Bound (i+1), product `apply` Forall [] tv1) 
                   `extend` (Bound  i   , product `apply` Forall [] tv2)
    (sinn, tinn) <- infer (i+2) env' inn
    return (seq ∘ product ∘ sinn, seq ∘ sinn `apply` tinn)
infer i env (Abs body) = do
    tv <- inferDuplicity body <$> fresh
    let env' = env `extend` (Bound i, Forall [] tv)
    (s1, t1) <- infer (i+1) env' body
    return (s1, apply s1 tv :=> t1)
infer i env New  = return (nullSubst, TypeBit  :=> TypeQBit)
infer i env Meas = return (nullSubst, TypeQBit :=> TypeDup TypeBit)
infer i env Unit = return (nullSubst, TypeDup TypeUnit)

productExponential :: Type -> Type -> Infer Type
productExponential l r
    | nexps l == nexps r = return $ iterate bang (debang l :>< debang r) !! nexps l
    | otherwise = throwError $ ProductDuplicityError l r
    where
        nexps :: Type -> Int
        nexps (TypeDup a) = 1 + nexps a
        nexps a = 0

tr :: (Show a, Monad m) => a -> m ()
tr x = trace (show x) (return ())

-- | Infers type of a Gate
inferGate :: Gate -> Type
inferGate g = gateType $ case g of
    GFRDK -> 3
    GTOF  -> 3
    GSWP  -> 2
    GCNOT -> 2
    _     -> 1
    where
        gateType' n = foldr (:><) TypeQBit (replicate (n-1) TypeQBit)
        gateType  n = gateType' n :=> gateType' n

subtypeCheck :: Type -> Type -> Infer ()
subtypeCheck (a :=> _) b 
    | b <: a    = return ()
    | otherwise = throwError $ SubtypeFailError a b

-- | Return whether a type is a subtype of another type.
(<:) :: Type -> Type -> Bool
TypeDup  a  <: TypeDup  b   = TypeDup a <: b
TypeDup  a  <: TypeFlex b   = True 
TypeDup  a  <:          b   = a  <: b
(a1 :>< a2) <: (TypeDup (b1 :><  b2)) = a1 <: TypeDup b1 && a2 <: TypeDup b2
(a1 :>< a2) <: (b1 :><  b2) = a1 <: b1 && a2 <: b2
(a' :=>  b) <: (a :=>   b') = a  <: a' && b  <: b'
TypeFlex a  <: TypeDup  b   = True 
TypeFlex a  <:          b   = True
a           <: TypeFlex b   = True
a           <: TypeVar  b   = True
a           <:          b   = a == b

-- Given a function (or let) body and a bodytype, if the variable bound is used many times
--  it must be unlinear !t. If its used once or zero times it could have either
--  a linear or unlinear type, thus having flex.
inferDuplicity :: Term -> Type -> Type
inferDuplicity e t
    | headCount e <= 1 = flex t
    | otherwise        = bang t

(!?) :: Term -> Type -> Type
(!?) = inferDuplicity

-- | Looks up a free or bound variable from the environment
lookupEnv :: TypeEnv -> Named -> Infer (Subst, Type)
lookupEnv (TypeEnv env) x = case Map.lookup x env of
        Nothing -> throwError $ NotInScopeError x
        Just  s -> do t <- instantiate s
                      return (nullSubst, t)

linearcheck :: Term -> Type -> Infer ()
linearcheck e = \case
    TypeDup t -> return ()
    _notdup   -> if headCount e <= 1
                    then return ()
                    else throwError $ LinearityError e

-- | The number of variables bound to the head
headCount :: Term -> Integer
headCount = cO 0
    where cO i = \case
            Idx   j    -> if i - j == 0 then 1 else 0
            Abs e      -> cO (i+1) e
            App l r    -> cO i l + cO i r
            IfEl b t f -> cO i b + max (cO i t) (cO i f)
            Tup l r    -> cO i l + cO i r
            Let _ e    -> cO (i+2) e
            -- \x . let (a,b) = x in M
            e -> 0

typecheckTerm :: Term -> Either TypeError Scheme
typecheckTerm e = runInfer (infer 0 emptyEnv e)

typecheckProgram :: [Function] -> [Either TypeError (String, Type)]
typecheckProgram fs = map (checkFunc env) fs
    where env = genEnv fs

showTypes :: [Either TypeError (String, Type)] -> IO ()
showTypes = putStrLn . intercalate "\n\n" . map st
    where st (Left  err) = "*** Exception:\n" ++ show err
          st (Right (name, typ)) = name ++ " : " ++ show typ

runtc :: String -> [Either TypeError (String, Type)]
runtc prog = typecheckProgram (run prog)

runtcFile :: FilePath -> IO [Either TypeError (String, Type)]
runtcFile path = runtc <$> readFile path

-- | Run the inferement code. The result is a type scheme or an exception.
runInfer :: Infer (Subst, Type) -> Either TypeError Scheme
runInfer m = case evalState (runExceptT m) 0 of
        Left  err -> Left err
        Right res -> Right $ closeOver res

checkFunc :: TypeEnv -> Function -> Either TypeError (String, Type)
checkFunc env (Func name qtype term) = do
    Forall _ itype <- runInfer (infer 0 env term)
    s <- evalState (runExceptT (equal qtype itype)) 0
    return (name, s)


-- | Gives the unified type of the type from the type signature
--   and the inferred type.  
equal :: Type -> Type -> Infer Type
equal typ inf = do
    sub <- unify typ inf
    return $ apply sub typ

-- | Generate environment with function signatures 
genEnv :: [Function] -> TypeEnv
genEnv = TypeEnv . Map.fromList . map f
    where f (Func n t _) = (Free n, generalize emptyEnv t)

inferExp :: String -> Either TypeError Type
inferExp prog = do
    let [Func _ _ term] = run ("f : a f = " ++ prog)
    Forall _ type' <- runInfer (infer 0 emptyEnv term)
    -- return $ deflexType type'
    return type'

-- | Run typechecker on program
typecheck :: [Function] -> Either TypeError ()
typecheck = mapM_ . checkFunc . genEnv <*> id