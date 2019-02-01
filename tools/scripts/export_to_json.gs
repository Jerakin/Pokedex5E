// Credit Christian Boutin
// https://gist.github.com/IronistM/8be09ebd4c5a4a58c63b
// Adapted by Mattias Hedberg

function exportSheetAsJSON() {
  var sheet = SpreadsheetApp.getActiveSheet();
  var rows = sheet.getDataRange();
  var numRows = rows.getNumRows();
  var numCols = rows.getNumColumns();
  var values = rows.getValues();
  
  var output = "";
  output += "{\""+sheet.getName()+"\" : {\n";
  var header = values[0];
  for (var i = 1; i < numRows; i++) {
    if (i > 1) output += " , \n";
    var row = values[i];
    output += "\""+row[0]+"\" : {";
    for (var a = 1;a<numCols;a++){
      if (header[a].length > 0) {
        if (a > 1) output += " , ";
        var cell_text = row[a];
        if (typeof cell_text === 'string') {
          cell_text = cell_text.replace(/(\r\n|\n|\r)/gm,";");
          cell_text = cell_text.replace(/["']/g, "");
        }
        output += "\""+header[a]+"\" : \""+cell_text+"\"";
      }
    }
    output += "}";
    //Logger.log(row);
    
  }
  output += "\n}}";
  Logger.log(output);
  DriveApp.createFile(sheet.getName()+".json", output, MimeType.PLAIN_TEXT);

};