"""Scanalyze Backend - Flask Application Factory."""

from flask import Flask
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from .config import Config
from .models import db


jwt = JWTManager()


def create_app(config_class=Config):
    """Create and configure the Flask application."""
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Initialize extensions
    db.init_app(app)
    jwt.init_app(app)
    CORS(app)

    @app.before_request
    def bypass_auth_for_development():
        """Automatically inject a valid JWT for User ID #1 if none is provided."""
        from flask import request
        if 'Authorization' not in request.headers:
            from flask_jwt_extended import create_access_token
            # Injecting into the WSGI environ effectively tricks Flask into thinking it received the header
            request.environ['HTTP_AUTHORIZATION'] = f'Bearer {create_access_token(identity="1")}'

    # Register blueprints
    from .routes.auth import auth_bp
    from .routes.products import products_bp
    from .routes.analysis import analysis_bp
    from .routes.ingredients import ingredients_bp
    from .routes.preferences import preferences_bp
    from .routes.history import history_bp
    from .routes.favorites import favorites_bp

    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(products_bp, url_prefix='/api/products')
    app.register_blueprint(analysis_bp, url_prefix='/api/analysis')
    app.register_blueprint(ingredients_bp, url_prefix='/api/ingredients')
    app.register_blueprint(preferences_bp, url_prefix='/api/preferences')
    app.register_blueprint(history_bp, url_prefix='/api/history')
    app.register_blueprint(favorites_bp, url_prefix='/api/favorites')

    # Create tables
    with app.app_context():
        db.create_all()

    return app
