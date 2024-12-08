	
resource "aws_instance" "inst1"{
	ami = var.ami
	instance_type = var.it
	key_name = var.key
	


}

data "aws_subnets" "subnets1"{
	depends_on = [aws_instance.inst1]
}
data "aws_vpc" "selected"{
	id = "vpc-04b812651542f9c33"
}



resource "aws_lb_target_group" "example"{
	name = var.tgname
	port = var.port
	protocol = "HTTP"
	target_type = "instance"
	vpc_id = data.aws_vpc.selected.id

  	health_check{
		port = 5000
		}

}
resource "aws_lb_target_group_attachment" "test"{
	depends_on = [aws_lb_target_group.example]
	target_group_arn = aws_lb_target_group.example.arn
	target_id = aws_instance.inst1.id	
	port = 5000
}
	

resource "aws_lb" "test" {
	depends_on = [data.aws_subnets.subnets1,aws_lb_target_group.example]
	name = var.lbname
	internal = false
	load_balancer_type = "application"
	subnets = data.aws_subnets.subnets1.ids
	enable_deletion_protection = true
		
	tags = {
		name = "aws_lb"
		}
}

resource "aws_lb_listener" "listener"{
	depends_on = [aws_lb_target_group.example]
	load_balancer_arn = aws_lb.test.arn
	port = "5000"
	protocol = "HTTP"
	
	default_action {
		type = "forward"
		target_group_arn = aws_lb_target_group.example.arn
		}
}


resource "aws_lb_listener_rule" "static"{
	depends_on = [aws_lb_listener.listener]
	listener_arn = aws_lb_listener.listener.arn
	priority = 100
	  condition {
    		path_pattern {
      		values = ["/"]
    		}	
		}
	action {
		type = "forward"
		target_group_arn = aws_lb_target_group.example.arn
		}
		}


resource "null_resource" "nl1" {
	depends_on = [aws_lb_listener_rule.static,aws_instance.inst1]
	
	connection {
		type ="ssh"
		user = "ec2-user"
		private_key = file ("./keypair29thnov.pem")
		host = aws_instance.inst1.public_ip
		}
	
	provisioner "file"{
		source = "app.py"
		destination = "/home/ec2-user/app.py"
}	

	provisioner "remote-exec" {
		inline = [
		"cd /home/ec2-user/",
		"sudo yum install -y python3",
		"sudo yum install -y pip",
		"pip install --upgrade pip",
		"pip install Flask",
		"flask run --host=0.0.0.0",
		]
}
}
