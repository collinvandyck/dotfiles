# Load custom functions from the functions directory
SCRIPT_PATH="${0:A:h}"
for s in ${SCRIPT_PATH}/functions/*; do
	source "${s}"
done

