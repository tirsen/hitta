# hitta
This is a(nother) Rails plugin for full-text search. Instead of using an external storage for the index this stores the index in the database. This makes it possible to use full text search along with joins and other types of more structured database searches as well as makes it much friendlier in clustered scenarios as the database takes care of locking and other concurrency issues. ("Hitta" means "find" in Swedish.)
