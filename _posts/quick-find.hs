module Main where

-- Connect a and b --
union' :: (Int, Int) -> [Int] -> [Int]
union' (a, b) tree  = map (replace (x, y)) tree
    where x = tree!!a
          y = tree!!b
          replace (p, q) a
                | (a == q)  = p
                | otherwise = a

--find if a and b are connected--
find' :: (Int, Int) -> [Int] -> Bool
find' (a, b) tree = (tree!!a) == (tree!!b)


replaceAt :: (Int, Int) -> [Int] -> [Int]
replaceAt (x, i) list =
    let (p, q) = splitAt i list
    in p ++ [x] ++ tail q

root :: Int -> [Int] -> Int
root a tree
    | (a == b)  = a
    | otherwise = root b tree
    where b = tree!!a

union :: (Int, Int) -> [Int] -> [Int]
union (a, b) tree = replaceAt (rootA, rootB) tree
    where rootA = root a tree
          rootB = root b tree

find :: (Int, Int) -> [Int] -> Bool
find (a, b) tree = (root a tree) == (root b tree)

weightUnion :: (Int, Int) -> ([Int], [Int]) -> ([Int], [Int])
weightUnion (a, b) (tree, size)
    | (size!!rootA >= size!!rootB)  = (replaceT rootA rootB, replaceS rootA rootB)
    | otherwise                     = (replaceT rootB rootA, replaceS rootB rootA)
    where rootA = root a tree
          rootB = root b tree
          replaceT x y = replaceAt (x, y) tree
          replaceS x y = replaceAt (size!!x + size!!y, x) size

pcRoot :: Int -> [Int] -> (Int, [Int])
pcRoot a tree
    | (a == b)  = (a, tree)
    | otherwise = pcRoot b (replaceAt (tree!!b,  a) tree)
    where b = tree!!a

quickUnion :: (Int, Int) -> ([Int], [Int]) -> ([Int], [Int])
quickUnion (a, b) (tree, size)
    | (size!!rootA >= size!!rootB) = (replaceT rootA rootB, replaceS rootA rootB)
    | otherwise                    = (replaceT rootB rootA, replaceS rootB rootA)
    where (rootA, tree') = pcRoot a tree
          (rootB, tree'') = pcRoot b tree'
          replaceT x y = replaceAt (x, y) tree''
          replaceS x y = replaceAt (size!!x + size!!y, x) size

quickFind :: (Int, Int) -> [Int] -> Bool
quickFind (a, b) tree = (fst $ pcRoot a tree) == (fst $ pcRoot b tree)


wStep1  = weightUnion (1, 2) ([0,1..9], replicate 10 1)
-- ([0,1,1,3,4,5,6,7,8,9],[1,2,1,1,1,1,1,1,1,1])
wStep2  = weightUnion (3, 1) wStep1
-- ([0,1,1,1,4,5,6,7,8,9],[1,3,1,1,1,1,1,1,1,1])

step1  = union (1, 2) [0,1..9]
-- [0,1,1,3,4,5,6,7,8,9]
step2  = union (3, 1) step1
-- [0,3,1,3,4,5,6,7,8,9]


main :: IO()
main = do  putStrLn "Quick Find Algorithm"
           print $ (union' (6, 1) [0, 1, 1, 8, 8, 0, 0, 1, 8, 8])
           print $ (find'  (3, 1) [0, 1, 1, 8, 8, 0, 0, 1, 8, 8])
           print $ (union  (6, 1) [0, 1, 1, 8, 8, 0, 0, 1, 8, 8])
           print $ (find   (3, 1) [0, 1, 1, 8, 8, 0, 0, 1, 8, 8])
           print $ wStep1
           print $ step1
