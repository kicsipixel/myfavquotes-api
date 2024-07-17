# Swift Server-Side Authentication: Bearer Authentication and Hummingbird 2


### Create an `.env` file with the following:

```
DATABASE_HOST=db
DATABASE_NAME=myfav_quotes
DATABASE_USERNAME=hb_usernam3
DATABASE_PASSWORD=s3cr3t
PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_USER=hb_usernam3
POSTGRES_PASSWORD=s3cr3t
POSTGRES_DB=myfav_quotes
POSTGRES_HOST=localhost

# pgAdmin
PGADMIN_DEFAULT_EMAIL=pgAdmin@mail.com
PGADMIN_DEFAULT_PASSWORD=pgAdmin_secr3t
```

### Build image
```
$ docker compose build
```

### Run the server

```
$ docker compose up app -d
```

### Run pgAdmin

```
$ docker compose up pgadmin -d
```
Check [the tutorial](https://medium.com/@kicsipixel/install-pgadmin-with-postgresql-database-using-docker-ded3e2dfbe3b) how to set it up.

### Test
Use the attached [RapidAPI](https://paw.cloud)  [`My_Fav_Quotes_BasicAuth.paw`](My_Fav_Quotes_BasicAuth.paw) file.

### Endpoints

 HTTP Method | Endpoint                                 | Description                             |
| -----------| ---------------------------------------- | --------------------------------------- |
| __GET__    | http://127.0.0.1:8080/health             | Server status                           |
| __GET__    | http://127.0.0.1:8080/api/v1/quotes      | Lists all the quotes in the database    |
|__GET__     |http://127.0.0.1:8080/api/v1/quotes/{:id} | Shows a single quote with given id      |
| __POST__   |http://127.0.0.1:8080/api/v1/quotes       | Creates a new quote                     |
|__PUT__     |http://127.0.0.1:8080/api/v1/quotes/{:id} | Updates the quote with the given id     |
|__DELETE__  |http://127.0.0.1:8080/api/v1/quotes/{:id} | Removes the quote with id from database |
|__POST__ | http://127.0.0.1:8080/api/v1/users | Create new user |

