# spec/middleware/api_error_handler_spec.rb
require 'rails_helper'

RSpec.describe ApiErrorHandler do
  let(:app) { ->(env) { [ 200, env, 'app' ] } }
  let(:middleware) { described_class.new(app) }

  describe '#call' do
    context 'when no error occurs' do
      it 'passes the request through to the app' do
        env = { 'PATH_INFO' => '/api/v1/health' }
        status, _headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq('app')
      end
    end

    context 'when an error occurs in an API route' do
      let(:app) { ->(env) { raise StandardError, 'Something went wrong' } }

      it 'catches the error and returns a JSON response for API requests' do
        env = {
          'PATH_INFO' => '/api/v1/health',
          'HTTP_ACCEPT' => 'application/json'
        }

        status, headers, body = middleware.call(env)

        expect(status).to eq(500)
        expect(headers['Content-Type']).to eq('application/json')

        json_body = JSON.parse(body.first)
        expect(json_body['status']).to eq('error')
        expect(json_body['message']).to eq('Internal Server Error')
        expect(json_body['details']).to include('Something went wrong')
      end

      it 'includes error details in development mode' do
        allow(Rails.env).to receive(:development?).and_return(true)

        env = {
          'PATH_INFO' => '/api/v1/health',
          'HTTP_ACCEPT' => 'application/json'
        }

        _status, _headers, body = middleware.call(env)

        json_body = JSON.parse(body.first)
        expect(json_body['details']).to include('Something went wrong')
        expect(json_body).to have_key('backtrace')
      end

      it 'does not include backtrace in production mode' do
        allow(Rails.env).to receive_messages(development?: false, test?: false)

        env = {
          'PATH_INFO' => '/api/v1/health',
          'HTTP_ACCEPT' => 'application/json'
        }

        _status, _headers, body = middleware.call(env)

        json_body = JSON.parse(body.first)
        expect(json_body).not_to have_key('backtrace')
      end
    end

    context 'when an error occurs in a non-API route' do
      let(:app) { ->(env) { raise StandardError, 'Something went wrong' } }

      it 're-raises the error for non-API requests' do
        env = { 'PATH_INFO' => '/not-api' }

        expect {
          middleware.call(env)
        }.to raise_error(StandardError, 'Something went wrong')
      end
    end

    context 'with different error types' do
      let(:error_mapping) do
        {
          'ActiveRecord::RecordNotFound' => 404,
          'ActionController::ParameterMissing' => 400,
          'ActiveRecord::RecordInvalid' => 422,
          'Exceptions::ForbiddenError' => 403,
          'ActionController::RoutingError' => 404
        }
      end

      it 'maps errors to appropriate status codes' do
        error_mapping.each do |error_class, status_code|
          error_instance = error_class.constantize.new rescue error_class.constantize.new('test')
          app_with_error = ->(env) { raise error_instance }
          middleware_with_error = described_class.new(app_with_error)

          env = {
            'PATH_INFO' => '/api/v1/health',
            'HTTP_ACCEPT' => 'application/json'
          }

          status, _, _ = middleware_with_error.call(env)
          expect(status).to eq(status_code), "Expected #{error_class} to map to status #{status_code}, but got #{status}"
        end
      end
    end
  end
end
