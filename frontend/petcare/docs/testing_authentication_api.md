# Testing PetCare Authentication API with Postman

This guide will walk you through testing the Authentication API endpoints using Postman.

## Prerequisites

1. [Postman](https://www.postman.com/downloads/) installed on your computer
2. PetCare API running locally or on a server

## Setup

1. Open Postman
2. Create a new collection named "PetCare API"
3. Set up environment variables (optional but recommended):
   - Click on the "Environments" tab
   - Create a new environment (e.g., "PetCare Local")
   - Add the following variables:
     - `base_url`: `https://localhost:7267` (adjust port as needed)
     - `token`: Leave this empty initially

## Testing Registration

1. Create a new request in the PetCare API collection
2. Name it "User Registration"
3. Set the method to `POST`
4. Set the URL to `{{base_url}}/api/auth/register` (or `https://localhost:7267/api/auth/register` if not using environment variables)
5. Go to the "Headers" tab and add:
   - `Content-Type`: `application/json`
6. Go to the "Body" tab, select "raw", and make sure "JSON" is selected
7. Enter the following JSON:

```json
{
  "fullName": "Test User",
  "email": "testuser@example.com",
  "password": "Test@123",
  "confirmPassword": "Test@123",
  "phone": "0912345678",
  "address": "123 Test Street, Test City",
  "latitude": 10.7758439,
  "longitude": 106.7017555
}
```

8. Click "Send" to submit the request
9. You should receive a `201 Created` response with a JSON payload containing the user information

### Testing Registration Validation

Try sending invalid data to test validation:

**Missing Required Fields**:
```json
{
  "fullName": "",
  "email": "invalid-email",
  "password": "123",
  "confirmPassword": "456"
}
```

**Email Already in Use**:
Send the same registration request twice with the same email.

## Testing Login

1. Create a new request in the PetCare API collection
2. Name it "User Login"
3. Set the method to `POST`
4. Set the URL to `{{base_url}}/api/auth/login`
5. Add the `Content-Type: application/json` header
6. In the "Body" tab, enter:

```json
{
  "email": "testuser@example.com",
  "password": "Test@123"
}
```

7. Click "Send"
8. You should receive a `200 OK` response with user information and a JWT token

9. **Saving the Token** (if using environment variables):
   - In the "Tests" tab of your login request, add this script:

```javascript
var response = pm.response.json();
if (response.success && response.data && response.data.token) {
    pm.environment.set("token", response.data.token);
}
```

### Testing Login Validation

Try these test cases:

**Invalid Credentials**:
```json
{
  "email": "testuser@example.com",
  "password": "WrongPassword"
}
```

**Invalid Email Format**:
```json
{
  "email": "not-an-email",
  "password": "Test@123"
}
```

## Testing Protected Endpoints

Now that you have a token, you can test protected endpoints:

1. Create a new request (e.g., "Get User Profile")
2. Set the method to `GET`
3. Set the URL to `{{base_url}}/api/users/[user_id]` (replace `[user_id]` with the actual user ID)
4. In the "Headers" tab, add:
   - `Authorization`: `Bearer {{token}}` (or paste the actual token if not using environment variables)
5. Click "Send"
6. You should receive a `200 OK` response with the user's profile data

## Common Issues and Troubleshooting

### SSL Certificate Errors

If testing locally with HTTPS, you might encounter SSL certificate errors. In Postman:

1. Go to Settings (gear icon)
2. Turn off "SSL certificate verification" in the General tab
3. Remember to turn it back on when testing production APIs

### Token Expired

If you get a `401 Unauthorized` response with a message about the token being expired:

1. Run the login request again to get a new token
2. The token will automatically be saved to your environment if you've set up the test script

### CORS Issues

If testing from a browser and encountering CORS issues, make sure your API has CORS configured correctly for your client origins.

## Postman Collection

For convenience, you can import this Postman collection:

1. In Postman, click "Import"
2. Select the "Link" tab
3. Enter this gist URL: [PetCare API Collection Gist URL]
4. Click "Import"

## Additional Resources

- [Postman Documentation](https://learning.postman.com/docs/getting-started/introduction/)
- [JWT.io](https://jwt.io/) - Useful for decoding and verifying JWT tokens