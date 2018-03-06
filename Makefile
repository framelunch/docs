id=""
-include $(CURDIR)/.env

project:
	bash utils/new-project.sh $(CONTAINER_NAME) $(id)
