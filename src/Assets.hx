import dn.heaps.slib.*;

class Assets {
	public static var SFX = dn.heaps.Sfx.importDirectory("sfx");

	public static var fontPixel : h2d.Font;
	public static var fontTiny : h2d.Font;
	public static var fontSmall : h2d.Font;
	public static var fontMedium : h2d.Font;
	public static var fontLarge : h2d.Font;
	public static var tiles : SpriteLib;

	static var initDone = false;
	public static function init() {
		if( initDone )
			return;
		initDone = true;

		// dn.heaps.Sfx.setGroupVolume(0,1);
		// dn.heaps.Sfx.setGroupVolume(1,0.5);

		fontPixel = hxd.Res.fonts.minecraftiaOutline.toFont();
		fontTiny = hxd.Res.fonts.barlow_condensed_medium_regular_9.toFont();
		fontSmall = hxd.Res.fonts.barlow_condensed_medium_regular_11.toFont();
		fontMedium = hxd.Res.fonts.barlow_condensed_medium_regular_17.toFont();
		fontLarge = hxd.Res.fonts.barlow_condensed_medium_regular_32.toFont();

		tiles = dn.heaps.slib.assets.Atlas.load("atlas/tiles.atlas");
		tiles.defineAnim("heroRun", "0(2), 1(1), 2(2), 1(1)");
		tiles.defineAnim("heroIdle", "0(10), 1(1), 2(8)");
		tiles.defineAnim("heroThrow", "0(1), 1(999)");
		tiles.defineAnim("heroPunch", "0(2), 1(1), 2(2), 3(3)");

		tiles.defineAnim("guardRun", "0(2), 1(1), 2(2), 1(1)");
		tiles.defineAnim("guardWalk", "0(3), 1(1), 2(3), 1(1)");
		tiles.defineAnim("guardShoot", "1(3), 0(1), 1(4)");
		tiles.defineAnim("guardShootDown", "1(1), 0(2), 1(4)");
		tiles.defineAnim("guardHit", "0(1), 1(2), 2(9999)	");
		tiles.defineAnim("stun", "0-3,3,2,1");
	}
}