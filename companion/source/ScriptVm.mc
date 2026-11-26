// Mini-interpreteur de validation : DSL restreint, sans boucle ni appel
// systeme arbitraire. Les seules primitives autorisees sont les sondes de
// FeatureProbes. Module pur, testable sur la face et dans le compagnon.
//
// Grammaire (une instruction par ligne) :
//   CHECK <id>                    lance une sonde
//   EXPECT <champ> <op> <valeur>  verifie le dernier rapport
//   PRINT <texte>                 ajoute une ligne au rapport
//   LOG                           trace le rapport courant
//   SKIP <texte>                  ligne ignoree explicitement
//   END                           fin du script
//
// Operateurs : ==, !=, >, < ; champs : verdict, lines, id.

using Toybox.Lang;

module ScriptVm {
    const MAX_LINES = 32;
    const MAX_CHARS = 2048;
    const MAX_LINE_CHARS = 256;

    function tokens(line as Lang.String) as Lang.Array {
        var out = [] as Lang.Array;
        var current = "";
        for (var i = 0; i < line.length(); i++) {
            var c = line.substring(i, i + 1) as Lang.String;
            if (c.equals(" ")) {
                if (current.length() > 0) { out.add(current); current = ""; }
            } else {
                current += c;
            }
        }
        if (current.length() > 0) { out.add(current); }
        return out;
    }

    function lines(script as Lang.String) as Lang.Array {
        var out = [] as Lang.Array;
        var rest = script;
        while (true) {
            var found = rest.find("\n");
            if (found == null) {
                out.add(rest);
                break;
            }
            var pos = found as Lang.Number;
            out.add(rest.substring(0, pos));
            rest = rest.substring(pos + 1, rest.length());
        }
        return out;
    }

    function field(report as Lang.Dictionary, name as Lang.String) as Lang.String {
        if (name.equals("verdict")) { return report.get(:verdict) as Lang.String; }
        if (name.equals("id")) { return report.get(:id) as Lang.String; }
        if (name.equals("lines")) {
            var rows = report.get(:lines) as Lang.Array;
            return rows.size().toString();
        }
        return "absent";
    }

    function compare(left as Lang.String, op as Lang.String, right as Lang.String) as Lang.Boolean {
        if (op.equals("==")) { return left.equals(right); }
        if (op.equals("!=")) { return !left.equals(right); }
        var l = left.toNumber();
        var r = right.toNumber();
        if (op.equals(">")) { return l > r; }
        if (op.equals("<")) { return l < r; }
        return false;
    }

    function run(script as Lang.String, ctx as Lang.Dictionary) as Lang.Dictionary {
        var out = [] as Lang.Array;
        if (script.length() > MAX_CHARS) {
            return {:ok => false, :lines => ["ERREUR script > 2048 caracteres"] as Lang.Array,
                    :reason => "trop long"} as Lang.Dictionary;
        }
        var rows = lines(script);
        if (rows.size() > MAX_LINES) {
            return {:ok => false, :lines => ["ERREUR script > 32 lignes"] as Lang.Array,
                    :reason => "trop de lignes"} as Lang.Dictionary;
        }
        var last = null as Lang.Dictionary or Null;
        var ok = true;
        for (var i = 0; i < rows.size(); i++) {
            var row = rows[i] as Lang.String;
            if (row.length() > MAX_LINE_CHARS) {
                out.add("ERREUR ligne " + i.format("%d") + " > 256 caracteres");
                ok = false;
                continue;
            }
            var t = tokens(row);
            if (t.size() == 0) { continue; }
            var cmd = t[0] as Lang.String;
            if (cmd.equals("SKIP")) { continue; }
            if (cmd.equals("END")) { break; }
            if (cmd.equals("PRINT")) {
                var text = "";
                for (var k = 1; k < t.size(); k++) { text += (t[k] as Lang.String) + " "; }
                out.add(text);
                continue;
            }
            if (cmd.equals("LOG")) {
                if (last != null) {
                    var r = last as Lang.Dictionary;
                    out.add((r.get(:id) as Lang.String) + " logged");
                }
                continue;
            }
            if (cmd.equals("CHECK")) {
                if (t.size() < 2) { out.add("ERREUR CHECK sans id"); ok = false; continue; }
                last = FeatureProbes.probe(t[1] as Lang.String, ctx);
                out.add("CHECK " + (t[1] as Lang.String) + " -> " +
                        (last as Lang.Dictionary).get(:verdict) as Lang.String);
                continue;
            }
            if (cmd.equals("EXPECT")) {
                if (last == null || t.size() < 4) {
                    out.add("ERREUR EXPECT invalide"); ok = false; continue;
                }
                var actual = field(last as Lang.Dictionary, t[1] as Lang.String);
                var pass = compare(actual, t[2] as Lang.String, t[3] as Lang.String);
                out.add((t[1] as Lang.String) + " " + (t[2] as Lang.String) + " " +
                        (t[3] as Lang.String) + " -> " + (pass ? "ok" : "fail"));
                if (!pass) { ok = false; }
                continue;
            }
            out.add("ERREUR primitive inconnue : " + cmd);
            ok = false;
        }
        return {:ok => ok, :lines => out, :reason => ok ? "termine" : "echec"} as Lang.Dictionary;
    }
}
