enum CardGameId {
  MAGIC(1),
  YU_GI_OH(4),
  POKEMON(5),
  FLESH_AND_BLOOD(6),
  DIGIMON(8),
  DRAGON_BALL_SUPER(9),
  VANGUARD(10),
  MY_HERO_ACADEMIA(14),
  ONE_PIECE(15),
  LORCANA(18),
  STAR_WARS(20),
  UNION_ARENA(21),
  RIFTBOUND(22);

  const CardGameId(this.value);
  final int value;
}
