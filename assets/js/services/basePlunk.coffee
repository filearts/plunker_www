module = angular.module "plunker.service.basePlunk", []

module.value "basePlunk",
  files: [
    filename: "index.html"
    content: """
      <!doctype html>
      <head>
        <meta charset="utf-8">
        <title>Base Plunk</title>
        <link rel="stylesheet" href="style.css">
        <script src="script.js"></script>
      </head>
      <body>
        <h1>Hello Plunker</h1>
      </body>
      </html> 
    """
  ,
    filename: "script.js"
    content: """
      // Add your code here
      
      
    """
  ,
    filename: "style.css"
    content: """
      /* Add your styles here */
      
      
    """
  ]