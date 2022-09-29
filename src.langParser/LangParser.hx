import dn.data.GetText;

class LangParser {
	public static function main() {
		var name = "sourceTexts";
		Sys.println("Building "+name+" file...");
		var entries = [];
		entries = entries.concat( GetText.parseSourceCode("src") );
		GetText.writePOT('res/lang/$name.pot', entries);
		Sys.println("Done.");
	}
}