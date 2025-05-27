# Razen Beta v0.1.69 - API Library Enhancements

**Release Date:** 2025-05-27  
**Author:** Prathmesh Barot, Basai Corporation (Solo Managed Organization)  
**Version:** beta v0.1.69

## Overview

This release focuses on significant improvements to the Razen API library, enhancing its reliability, functionality, and ease of use. The API library now provides more robust handling of HTTP requests, responses, and data extraction, making it easier for developers to integrate external services into their Razen applications.

## New Features and Improvements

### API Library Enhancements

- **Improved URL Decoding**: Fixed the `url_decode` function to properly handle URL-encoded strings using `percent_decode`, with better handling of inputs that don't contain '=' characters.

- **Enhanced Form Data Handling**: The `form_data` function now correctly formats key-value pairs for HTTP requests, properly handling both map and array inputs.

- **Robust API Configuration**: The `execute_api` function has been improved to properly extract and use API keys and other parameters, with better handling of default values and error cases.

- **Flexible API Call Options**: The `call` function now handles options as either a map or array, providing more flexibility for specifying headers, methods, and parameters.

- **Better Response Processing**: The `process_response` function has been updated to handle API responses more effectively, including improved JSON parsing and storage of raw response data for debugging.

- **Error Handling**: Added comprehensive error handling throughout the API functions to provide meaningful feedback for debugging.

## Bug Fixes

- Fixed issues with header array formatting in the `call` function
- Corrected the handling of nested arrays for headers
- Fixed URL decoding for strings without '=' characters
- Resolved issues with form data formatting for HTTP requests
- Fixed content type checking before consuming API responses

## Known Limitations

- **Nested Property Access**: The current parser does not support nested indexing with bracket notation (e.g., `data["headers"]["User-Agent"]`). Users need to access nested properties in multiple steps:
  ```
  put headers = data["headers"];
  put user_agent = headers["User-Agent"];
  ```

- **Headers Format in Call Function**: When using the `call` function with custom headers, the headers must be provided in a specific format to ensure proper processing.

## Examples

The `examples/api_operations.rzn` file has been updated to demonstrate all the API library functions, including:

- Basic GET requests
- POST requests with JSON data
- Form data submission
- Custom API configurations
- Error handling
- Various HTTP methods (GET, POST, PUT, DELETE, PATCH)

## Future Enhancements

- Add support for nested property access in the parser
- Improve error messages for malformed API calls
- Add support for more authentication methods
- Enhance documentation with more examples

## Installation

To upgrade to this version, use the standard Razen update process:

```bash
razen update
```

Or download the latest version from the [official website](https://razen-lang.org/downloads).

## Feedback

We welcome your feedback on these improvements! Please report any issues or suggestions through our [GitHub repository](https://github.com/BasaiCorp/Razen-Lang/issues) or [community forum](https://community.razen-lang.org).
