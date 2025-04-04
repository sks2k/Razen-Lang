# Razen Web Development

Razen provides powerful web development capabilities through its web properties. These properties allow you to create interactive web applications using the familiar Razen syntax while seamlessly integrating with HTML.

## Integration with HTML

Razen web code can be embedded in HTML files using the `<razen>` tag. The Razen interpreter will process these tags and execute the Razen code within them.

```html
<!DOCTYPE html>
<html>
<head>
    <title>Razen Web App</title>
</head>
<razen>
    # Your Razen code here
</razen>
<body>
    <!-- HTML content -->
</body>
</html>
```

## Web Variables

Razen web properties include specialized variables for web development. These variables are fully compatible with standard Razen variables and can be used together in the same script.

### Key Features

- **DOM Manipulation**: Easily access and modify HTML elements
- **Event Handling**: Attach event listeners to elements for interactive behavior
- **Form Handling**: Validate and process form submissions
- **AJAX and Fetch**: Make HTTP requests to interact with servers
- **Storage**: Use local storage, session storage, and cookies
- **Animation**: Create smooth animations and transitions

## File Extensions

Razen web files use the `.html.rzn` extension to indicate they contain both HTML and Razen code.

## Running Web Applications

Razen web applications can be run using the standard Razen runtime with the `razen-run` command:

```
razen-run myapp.html.rzn
```

This will process the Razen code and serve the resulting web application.