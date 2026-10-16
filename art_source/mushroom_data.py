"""Append-only mushroom identities. Heights are authored garden display metres."""
MUSHROOMS = [
    (278, 'Fly agaric', 'Amanita muscaria', 'c94632', .34, 8, 'agaric'),
    (279, 'Porcini', 'Boletus edulis', '94613b', .28, 9, 'bolete'),
    (280, 'Golden chanterelle', 'Cantharellus cibarius', 'eab044', .24, 7, 'funnel'),
    (281, 'Pearl oyster', 'Pleurotus ostreatus', 'a5a49d', .30, 7, 'oyster'),
    (282, 'Pink oyster', 'Pleurotus djamor', 'df8d9c', .28, 7, 'pink_oyster'),
    (283, 'Shiitake', 'Lentinula edodes', '8d5e40', .27, 9, 'shiitake'),
    (284, 'Common morel', 'Morchella esculenta', 'b49a61', .32, 10, 'morel'),
    (285, "Lion's mane", 'Hericium erinaceus', 'ece5cf', .30, 10, 'mane'),
    (286, 'Amethyst deceiver', 'Laccaria amethystina', '936fa9', .22, 7, 'amethyst'),
    (287, 'Shaggy inkcap', 'Coprinus comatus', 'e9e3d5', .36, 8, 'inkcap'),
]
BY_ID = {p[0]: p for p in MUSHROOMS}
