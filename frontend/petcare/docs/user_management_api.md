# PetCare API Documentation - User Management

## Overview

This document describes the user management API endpoints for the PetCare application. These endpoints allow administrators to manage users and roles in the system.

## Base URL

```
https://[your-domain]/api
```

Replace `[your-domain]` with your actual API domain (e.g., `localhost:7267` for local development).

## Authentication

All endpoints require JWT authentication. Include the received token in the `Authorization` header of your requests:

```
Authorization: Bearer [your-jwt-token]
```

Most endpoints also require specific role permissions. Unless otherwise specified, users can only access their own data, while administrators can access all data.

## User Management Endpoints

### 1. Get All Users

Retrieve a list of all users. Requires Admin role.

- **URL**: `/admin/users`
- **Method**: `GET`
- **Authentication Required**: Yes (Admin)

**Success Response**:
- **Code**: `200 OK`
- **Content**:

```json
{
  "success": true,
  "message": "Users retrieved successfully",
  "data": [
    {
      "id": 1,
      "fullName": "Admin User",
      "email": "admin@example.com",
      "phone": "0912345678",
      "address": "123 Admin Street",
      "latitude": 10.7758439,
      "longitude": 106.7017555,
      "roles": ["Admin", "User"],
      "createdAt": "2025-10-15T10:30:45Z"
    },
    {
      "id": 2,
      "fullName": "Regular User",
      "email": "user@example.com",
      "phone": "0987654321",
      "address": "456 User Avenue",
      "latitude": 10.7769,
      "longitude": 106.6983,
      "roles": ["User"],
      "createdAt": "2025-10-15T11:45:30Z"
    }
  ]
}
```

**Error Responses**:

- **Code**: `403 Forbidden` - User does not have admin privileges
- **Code**: `500 Internal Server Error` - Server error

### 2. Get User by ID

Retrieve a specific user by ID. Users can only access their own information, while admins can access any user's information.

- **URL**: `/admin/users/{id}`
- **Method**: `GET`
- **Authentication Required**: Yes
- **URL Parameters**: `id=[integer]` where `id` is the ID of the user to retrieve

**Success Response**:
- **Code**: `200 OK`
- **Content**:

```json
{
  "success": true,
  "message": "User retrieved successfully",
  "data": {
    "id": 1,
    "fullName": "Admin User",
    "email": "admin@example.com",
    "phone": "0912345678",
    "address": "123 Admin Street",
    "latitude": 10.7758439,
    "longitude": 106.7017555,
    "roles": ["Admin", "User"],
    "createdAt": "2025-10-15T10:30:45Z"
  }
}
```

**Error Responses**:

- **Code**: `403 Forbidden` - User trying to access another user's information without admin privileges
- **Code**: `404 Not Found` - User with the specified ID not found
- **Code**: `500 Internal Server Error` - Server error

### 3. Update User

Update a user's information. Users can only update their own information, while admins can update any user's information.

- **URL**: `/admin/users/{id}`
- **Method**: `PUT`
- **Authentication Required**: Yes
- **URL Parameters**: `id=[integer]` where `id` is the ID of the user to update

**Request Body**:

```json
{
  "fullName": "Updated User Name",
  "email": "updated@example.com",
  "phone": "0912345679",
  "address": "789 Updated Street",
  "latitude": 10.7758440,
  "longitude": 106.7017556,
  "password": "NewPassword123!"
}
```

**Notes**:
- All fields are optional; only include the fields you want to update
- If updating the email, the new email must not be in use by another user
- If updating the password, it must meet the password requirements

**Success Response**:
- **Code**: `200 OK`
- **Content**:

```json
{
  "success": true,
  "message": "User updated successfully",
  "data": {
    "id": 1,
    "fullName": "Updated User Name",
    "email": "updated@example.com",
    "phone": "0912345679",
    "address": "789 Updated Street",
    "latitude": 10.7758440,
    "longitude": 106.7017556,
    "roles": ["Admin", "User"],
    "createdAt": "2025-10-15T10:30:45Z"
  }
}
```

**Error Responses**:

- **Code**: `400 Bad Request` - Validation failed
- **Code**: `403 Forbidden` - User trying to update another user's information without admin privileges
- **Code**: `404 Not Found` - User with the specified ID not found
- **Code**: `409 Conflict` - Email already in use
- **Code**: `500 Internal Server Error` - Server error

### 4. Delete User

Delete a user. Requires Admin role.

- **URL**: `/admin/users/{id}`
- **Method**: `DELETE`
- **Authentication Required**: Yes (Admin)
- **URL Parameters**: `id=[integer]` where `id` is the ID of the user to delete

**Success Response**:
- **Code**: `200 OK`
- **Content**:

```json
{
  "success": true,
  "message": "User deleted successfully",
  "data": null
}
```

**Error Responses**:

- **Code**: `403 Forbidden` - User does not have admin privileges
- **Code**: `404 Not Found` - User with the specified ID not found
- **Code**: `500 Internal Server Error` - Server error

### 5. Get User Roles

Retrieve the roles assigned to a user. Users can only access their own roles, while admins can access any user's roles.

- **URL**: `/admin/users/{id}/roles`
- **Method**: `GET`
- **Authentication Required**: Yes
- **URL Parameters**: `id=[integer]` where `id` is the ID of the user

**Success Response**:
- **Code**: `200 OK`
- **Content**:

```json
{
  "success": true,
  "message": "User roles retrieved successfully",
  "data": ["Admin", "User"]
}
```

**Error Responses**:

- **Code**: `403 Forbidden` - User trying to access another user's roles without admin privileges
- **Code**: `404 Not Found` - User with the specified ID not found
- **Code**: `500 Internal Server Error` - Server error

### 6. Add Role to User

Add a role to a user. Requires Admin role.

- **URL**: `/admin/users/{id}/roles`
- **Method**: `POST`
- **Authentication Required**: Yes (Admin)
- **URL Parameters**: `id=[integer]` where `id` is the ID of the user

**Request Body**:

```json
{
  "roleName": "Admin"
}
```

**Success Response**:
- **Code**: `200 OK`
- **Content**:

```json
{
  "success": true,
  "message": "Role 'Admin' added to user successfully",
  "data": null
}
```

**Error Responses**:

- **Code**: `403 Forbidden` - User does not have admin privileges
- **Code**: `404 Not Found` - User with the specified ID or role not found
- **Code**: `500 Internal Server Error` - Server error

### 7. Remove Role from User

Remove a role from a user. Requires Admin role.

- **URL**: `/admin/users/{id}/roles/{roleName}`
- **Method**: `DELETE`
- **Authentication Required**: Yes (Admin)
- **URL Parameters**: 
  - `id=[integer]` where `id` is the ID of the user
  - `roleName=[string]` where `roleName` is the name of the role to remove

**Success Response**:
- **Code**: `200 OK`
- **Content**:

```json
{
  "success": true,
  "message": "Role 'Admin' removed from user successfully",
  "data": null
}
```

**Error Responses**:

- **Code**: `403 Forbidden` - User does not have admin privileges
- **Code**: `404 Not Found` - User with the specified ID or role not found
- **Code**: `500 Internal Server Error` - Server error

## Role Management Endpoints

### 1. Get All Roles

Retrieve a list of all roles. Requires Admin role.

- **URL**: `/admin/roles`
- **Method**: `GET`
- **Authentication Required**: Yes (Admin)

**Success Response**:
- **Code**: `200 OK`
- **Content**:

```json
{
  "success": true,
  "message": "Roles retrieved successfully",
  "data": [
    {
      "id": 1,
      "name": "User",
      "description": "Standard user with basic access"
    },
    {
      "id": 2,
      "name": "Admin",
      "description": "Administrator with full access"
    },
    {
      "id": 3,
      "name": "Moderator",
      "description": "Moderator with limited administrative privileges"
    }
  ]
}
```

**Error Responses**:

- **Code**: `403 Forbidden` - User does not have admin privileges
- **Code**: `500 Internal Server Error` - Server error

### 2. Get Role by ID

Retrieve a specific role by ID. Requires Admin role.

- **URL**: `/admin/roles/{id}`
- **Method**: `GET`
- **Authentication Required**: Yes (Admin)
- **URL Parameters**: `id=[integer]` where `id` is the ID of the role to retrieve

**Success Response**:
- **Code**: `200 OK`
- **Content**:

```json
{
  "success": true,
  "message": "Role retrieved successfully",
  "data": {
    "id": 1,
    "name": "User",
    "description": "Standard user with basic access"
  }
}
```

**Error Responses**:

- **Code**: `403 Forbidden` - User does not have admin privileges
- **Code**: `404 Not Found` - Role with the specified ID not found
- **Code**: `500 Internal Server Error` - Server error

### 3. Create Role

Create a new role. Requires Admin role.

- **URL**: `/admin/roles`
- **Method**: `POST`
- **Authentication Required**: Yes (Admin)

**Request Body**:

```json
{
  "name": "Moderator",
  "description": "Moderator with limited administrative privileges"
}
```

**Success Response**:
- **Code**: `201 Created`
- **Content**:

```json
{
  "success": true,
  "message": "Role created successfully",
  "data": {
    "id": 3,
    "name": "Moderator",
    "description": "Moderator with limited administrative privileges"
  }
}
```

**Error Responses**:

- **Code**: `400 Bad Request` - Validation failed
- **Code**: `403 Forbidden` - User does not have admin privileges
- **Code**: `409 Conflict` - Role with the same name already exists
- **Code**: `500 Internal Server Error` - Server error

### 4. Update Role

Update a role. Requires Admin role.

- **URL**: `/admin/roles/{id}`
- **Method**: `PUT`
- **Authentication Required**: Yes (Admin)
- **URL Parameters**: `id=[integer]` where `id` is the ID of the role to update

**Request Body**:

```json
{
  "name": "ContentModerator",
  "description": "Content moderator with specific privileges"
}
```

**Success Response**:
- **Code**: `200 OK`
- **Content**:

```json
{
  "success": true,
  "message": "Role updated successfully",
  "data": {
    "id": 3,
    "name": "ContentModerator",
    "description": "Content moderator with specific privileges"
  }
}
```

**Error Responses**:

- **Code**: `400 Bad Request` - Validation failed
- **Code**: `403 Forbidden` - User does not have admin privileges
- **Code**: `404 Not Found` - Role with the specified ID not found
- **Code**: `409 Conflict` - Another role with the same name already exists
- **Code**: `500 Internal Server Error` - Server error

### 5. Delete Role

Delete a role. Requires Admin role. Built-in roles (User, Admin) cannot be deleted.

- **URL**: `/admin/roles/{id}`
- **Method**: `DELETE`
- **Authentication Required**: Yes (Admin)
- **URL Parameters**: `id=[integer]` where `id` is the ID of the role to delete

**Success Response**:
- **Code**: `200 OK`
- **Content**:

```json
{
  "success": true,
  "message": "Role deleted successfully",
  "data": null
}
```

**Error Responses**:

- **Code**: `400 Bad Request` - Cannot delete built-in roles
- **Code**: `403 Forbidden` - User does not have admin privileges
- **Code**: `404 Not Found` - Role with the specified ID not found
- **Code**: `500 Internal Server Error` - Server error

### 6. Get Users in Role

Retrieve a list of users assigned to a specific role. Requires Admin role.

- **URL**: `/admin/roles/{id}/users`
- **Method**: `GET`
- **Authentication Required**: Yes (Admin)
- **URL Parameters**: `id=[integer]` where `id` is the ID of the role

**Success Response**:
- **Code**: `200 OK`
- **Content**:

```json
{
  "success": true,
  "message": "Users with role 'Admin' retrieved successfully",
  "data": [
    {
      "id": 1,
      "fullName": "Admin User",
      "email": "admin@example.com",
      "phone": "0912345678",
      "address": "123 Admin Street",
      "latitude": 10.7758439,
      "longitude": 106.7017555,
      "roles": ["Admin", "User"],
      "createdAt": "2025-10-15T10:30:45Z"
    }
  ]
}
```

**Error Responses**:

- **Code**: `403 Forbidden` - User does not have admin privileges
- **Code**: `404 Not Found` - Role with the specified ID not found
- **Code**: `500 Internal Server Error` - Server error

## Testing Examples

### Updating a User

```bash
curl -X PUT \
  https://localhost:7267/api/admin/users/1 \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "fullName": "Updated Name",
    "phone": "0912345679",
    "address": "Updated Address"
}'
```

### Adding a Role to a User

```bash
curl -X POST \
  https://localhost:7267/api/admin/users/2/roles \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "roleName": "Admin"
}'
```

### Creating a New Role

```bash
curl -X POST \
  https://localhost:7267/api/admin/roles \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Moderator",
    "description": "Moderator with limited administrative privileges"
}'```