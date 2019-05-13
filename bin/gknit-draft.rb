require 'gknit'

GKnit.draft(file: ARGV[0], template: ARGV[1], package: ARGV[2],
	    create_dir: ARGV[3], edit: ARGV[4])
