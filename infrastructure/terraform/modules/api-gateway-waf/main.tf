
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-api"
  description = "NextGen Discover REST API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

# --------------------------------------------------
# API Resources
# --------------------------------------------------

resource "aws_api_gateway_resource" "signup" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "signup"
}

resource "aws_api_gateway_resource" "login" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "login"
}

resource "aws_api_gateway_resource" "refresh" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "refresh"
}

resource "aws_api_gateway_resource" "profile" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "profile"
}

resource "aws_api_gateway_resource" "movies" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "movies"
}

resource "aws_api_gateway_resource" "movie_id" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.movies.id
  path_part   = "{id}"
}

resource "aws_api_gateway_resource" "movies_search" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.movies.id
  path_part   = "search"
}

resource "aws_api_gateway_resource" "movies_genre" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.movies.id
  path_part   = "genre"
}

resource "aws_api_gateway_resource" "movie_genre_value" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.movies_genre.id
  path_part   = "{genre}"
}

# --------------------------------------------------
# Notification API Resources
# --------------------------------------------------

resource "aws_api_gateway_resource" "notifications" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "notifications"
}

resource "aws_api_gateway_resource" "notifications_unread_count" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.notifications.id
  path_part   = "unread-count"
}

resource "aws_api_gateway_resource" "notification_event_id" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.notifications.id
  path_part   = "{eventId}"
}

resource "aws_api_gateway_resource" "notification_mark_read" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.notification_event_id.id
  path_part   = "read"
}

# --------------------------------------------------
# API Route Configuration
# --------------------------------------------------

locals {
  api_routes = {
    signup = {
      resource_id            = aws_api_gateway_resource.signup.id
      http_method            = "POST"
      authorization          = "NONE"
      path                   = "/signup"
      request_parameters     = {}
      integration_parameters = {}
    }

    login = {
      resource_id            = aws_api_gateway_resource.login.id
      http_method            = "POST"
      authorization          = "NONE"
      path                   = "/login"
      request_parameters     = {}
      integration_parameters = {}
    }

    refresh = {
      resource_id            = aws_api_gateway_resource.refresh.id
      http_method            = "POST"
      authorization          = "NONE"
      path                   = "/refresh"
      request_parameters     = {}
      integration_parameters = {}
    }

    profile = {
      resource_id            = aws_api_gateway_resource.profile.id
      http_method            = "GET"
      authorization          = "CUSTOM"
      path                   = "/profile"
      request_parameters     = {}
      integration_parameters = {}
    }

    movies_get = {
      resource_id            = aws_api_gateway_resource.movies.id
      http_method            = "GET"
      authorization          = "NONE"
      path                   = "/movies"
      request_parameters     = {}
      integration_parameters = {}
    }

    movies_post = {
      resource_id            = aws_api_gateway_resource.movies.id
      http_method            = "POST"
      authorization          = "CUSTOM"
      path                   = "/movies"
      request_parameters     = {}
      integration_parameters = {}
    }

    movie_id_get = {
      resource_id   = aws_api_gateway_resource.movie_id.id
      http_method   = "GET"
      authorization = "NONE"
      path          = "/movies/{id}"

      request_parameters = {
        "method.request.path.id" = true
      }

      integration_parameters = {
        "integration.request.path.id" = "method.request.path.id"
      }
    }

    movie_id_delete = {
      resource_id   = aws_api_gateway_resource.movie_id.id
      http_method   = "DELETE"
      authorization = "CUSTOM"
      path          = "/movies/{id}"

      request_parameters = {
        "method.request.path.id" = true
      }

      integration_parameters = {
        "integration.request.path.id" = "method.request.path.id"
      }
    }

    movies_search = {
      resource_id   = aws_api_gateway_resource.movies_search.id
      http_method   = "GET"
      authorization = "NONE"
      path          = "/movies/search"

      request_parameters = {
        "method.request.querystring.title" = true
      }

      integration_parameters = {
        "integration.request.querystring.title" = "method.request.querystring.title"
      }
    }

    movies_genre = {
      resource_id   = aws_api_gateway_resource.movie_genre_value.id
      http_method   = "GET"
      authorization = "NONE"
      path          = "/movies/genre/{genre}"

      request_parameters = {
        "method.request.path.genre" = true
      }

      integration_parameters = {
        "integration.request.path.genre" = "method.request.path.genre"
      }
    }

    # ------------------------------------------------
    # Notification Routes - All Require JWT
    # ------------------------------------------------

    notifications_get = {
      resource_id   = aws_api_gateway_resource.notifications.id
      http_method   = "GET"
      authorization = "CUSTOM"
      path          = "/notifications"

      request_parameters = {}

      integration_parameters = {
        "integration.request.header.X-Authenticated-User-Id" = "context.authorizer.userId"
      }
    }

    notifications_unread_count = {
      resource_id   = aws_api_gateway_resource.notifications_unread_count.id
      http_method   = "GET"
      authorization = "CUSTOM"
      path          = "/notifications/unread-count"

      request_parameters = {}

      integration_parameters = {
        "integration.request.header.X-Authenticated-User-Id" = "context.authorizer.userId"
      }
    }

    notification_mark_read = {
      resource_id   = aws_api_gateway_resource.notification_mark_read.id
      http_method   = "PATCH"
      authorization = "CUSTOM"
      path          = "/notifications/{eventId}/read"

      request_parameters = {
        "method.request.path.eventId" = true
      }

      integration_parameters = {
        "integration.request.path.eventId"                   = "method.request.path.eventId"
        "integration.request.header.X-Authenticated-User-Id" = "context.authorizer.userId"
      }
    }
  }
}

# --------------------------------------------------
# API Gateway Methods
# --------------------------------------------------

resource "aws_api_gateway_method" "routes" {
  for_each = local.api_routes

  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = each.value.resource_id
  http_method   = each.value.http_method
  authorization = each.value.authorization

  authorizer_id = each.value.authorization == "CUSTOM" ? aws_api_gateway_authorizer.jwt.id : null

  request_parameters = each.value.request_parameters
}

# --------------------------------------------------
# API Gateway Private ALB Integrations
# --------------------------------------------------

resource "aws_api_gateway_integration" "routes" {
  for_each = var.enable_api_integrations ? local.api_routes : {}

  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = each.value.resource_id
  http_method             = aws_api_gateway_method.routes[each.key].http_method
  integration_http_method = each.value.http_method

  type            = "HTTP_PROXY"
  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.main.id

  integration_target = var.api_alb_arn
  uri                = "http://${var.api_alb_dns_name}${each.value.path}"

  request_parameters = each.value.integration_parameters
}

# --------------------------------------------------
# API Gateway Deployment
# --------------------------------------------------

resource "aws_api_gateway_deployment" "main" {
  count = var.enable_api_integrations ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode({
      methods = {
        for key, method in aws_api_gateway_method.routes :
        key => {
          id                 = method.id
          authorization      = method.authorization
          authorizer_id      = method.authorizer_id
          request_parameters = method.request_parameters
        }
      }

      integrations = {
        for key, integration in aws_api_gateway_integration.routes :
        key => {
          id                 = integration.id
          uri                = integration.uri
          integration_target = integration.integration_target
          connection_id      = integration.connection_id
          request_parameters = integration.request_parameters
        }
      }
    }))
  }

  depends_on = [
    aws_api_gateway_integration.routes
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# --------------------------------------------------
# API Gateway Stage
# --------------------------------------------------

resource "aws_api_gateway_stage" "main" {
  count = var.enable_api_integrations ? 1 : 0

  rest_api_id   = aws_api_gateway_rest_api.main.id
  deployment_id = aws_api_gateway_deployment.main[0].id
  stage_name    = "dev"

  tags = var.tags
}

resource "aws_api_gateway_method_settings" "all" {
  count = var.enable_api_integrations ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main[0].stage_name
  method_path = "*/*"

  settings {
    logging_level      = "INFO"
    metrics_enabled    = true
    data_trace_enabled = false
  }
}

# --------------------------------------------------
# AWS WAF
# --------------------------------------------------

resource "aws_wafv2_web_acl" "main" {
  name        = "${var.project_name}-api-waf"
  description = "AWS WAF protection for NextGen Discover API Gateway"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedKnownBadInputs"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-api-waf"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}

resource "aws_wafv2_web_acl_association" "api_stage" {
  count = var.enable_api_integrations ? 1 : 0

  resource_arn = aws_api_gateway_stage.main[0].arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# --------------------------------------------------
# API Gateway VPC Link V2
# --------------------------------------------------

resource "aws_apigatewayv2_vpc_link" "main" {
  name = "${var.project_name}-vpc-link"

  subnet_ids = var.private_subnet_ids

  security_group_ids = [
    var.vpc_link_security_group_id
  ]

  tags = var.tags
}

# --------------------------------------------------
# JWT Lambda Authorizer
# --------------------------------------------------

resource "aws_api_gateway_authorizer" "jwt" {
  name            = "${var.project_name}-jwt-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.main.id
  type            = "TOKEN"
  identity_source = "method.request.header.Authorization"

  authorizer_uri = var.lambda_authorizer_invoke_arn

  authorizer_result_ttl_in_seconds = 0
}

# --------------------------------------------------
# Allow API Gateway to Invoke Lambda Authorizer
# --------------------------------------------------

resource "aws_lambda_permission" "api_gateway_authorizer" {
  statement_id  = "AllowAPIGatewayInvokeJWTAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_authorizer_function_arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.main.execution_arn}/authorizers/${aws_api_gateway_authorizer.jwt.id}"
}

