// Geometrie pure du diagnostic : une seule colonne, deux pages, et une grille
// qui reste a l'interieur du cercle du cadran quelles que soient les metriques
// de police. Aucun appel UI ici : la fonction est testable sur la face.

using Toybox.Lang;

module DiagLayout {
    // Calcule la grille. `lineH` et `titleH` sont mesures sur le device, puis
    // bornes par l'appelant ; cette fonction ne fait que placer les elements.
    function grid(width as Lang.Number, height as Lang.Number,
                  lineH as Lang.Number, titleH as Lang.Number,
                  footerLines as Lang.Number) as Lang.Dictionary {
        var rows = 7;
        var totalH = titleH + (rows + footerLines) * lineH;
        var boxW = (width * 66) / 100;
        var left = (width - boxW) / 2;
        var margin = (height * 10) / 100;
        var top = (height - totalH) / 2;
        if (top < margin) { top = margin; }
        if (top + totalH > height - margin) { top = height - margin - totalH; }
        // Si la grille est plus haute que la marge disponible, on recentre :
        // mieux vaut une marge plus faible qu'un contenu hors ecran.
        if (top < 0) {
            top = (height - totalH) / 2;
            if (top < 0) { top = 0; }
        }
        return {
            :boxW => boxW,
            :boxH => totalH,
            :left => left,
            :top => top,
            :rowY => top + titleH + lineH / 2,
            :footerY => top + titleH + rows * lineH + lineH / 2,
            :lineH => lineH,
            :rows => rows
        } as Lang.Dictionary;
    }
}
