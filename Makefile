id=""
-include $(CURDIR)/.env

_:
	bash utils/build.sh $(CONTAINER_NAME) $(id)

preview:
	bash utils/server.sh $(CONTAINER_NAME) $(id)

project:
	bash utils/new-project.sh $(CONTAINER_NAME) $(id)

update:
	bash utils/update.sh $(CONTAINER_NAME) $(id)
