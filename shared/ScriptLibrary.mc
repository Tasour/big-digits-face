// Scripts texte embarques : ils ne sont pas modifies a l'execution. Le MCP
// peut verifier la syntaxe d'un script, mais ne peut pas en injecter un dans
// l'app via MTP : seule une recompilation peut en ajouter un nouveau.

using Toybox.Lang;

module ScriptLibrary {
    const QUICK = "CHECK contract\nEXPECT verdict == ok\nPRINT verification rapide\nEND";
    const CONTRACT = "CHECK contract\nEXPECT verdict == ok\nEXPECT lines > 0\nEND";
    const SLEEP = "CHECK sleep\nEXPECT lines > 0\nEND";
    const ALL = "CHECK contract\nCHECK sleep\nCHECK light\nCHECK stress\nCHECK nsdr\nCHECK ble\nCHECK layout\nCHECK storage\nPRINT 8 sondes lancees\nEND";

    function names() as Lang.Array {
        return ["quick", "contract", "sleep", "all"] as Lang.Array;
    }

    function script(name as Lang.String) as Lang.String {
        if (name.equals("quick")) { return QUICK; }
        if (name.equals("contract")) { return CONTRACT; }
        if (name.equals("sleep")) { return SLEEP; }
        if (name.equals("all")) { return ALL; }
        return "PRINT script inconnu\nEND";
    }
}
