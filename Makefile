INSTALL_DIR := /usr/local/bin
EZ_HOME := ~/.ez

$(INSTALL_DIR)/ez: $(EZ_HOME)/ez
	mkdir -p ${INSTALL_DIR}
	sudo ln -s $< ${INSTALL_DIR}

