INSTALL_DIR := /usr/local/bin
EZ_HOME := ~/.ez-install


$(INSTALL_DIR)/ez:
	sudo mkdir -p ${INSTALL_DIR}
	sudo ln -s $(EZ_HOME)/ez $@

