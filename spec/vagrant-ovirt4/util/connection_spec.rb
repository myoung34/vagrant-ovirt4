require 'vagrant-ovirt4/util/connection'

describe VagrantPlugins::OVirtProvider::Util::Connection do
  class MockConnection
    def initialize(exception)
      @closed = false
      @exception = exception
    end

    def close
      raise @exception if @closed
      @closed = true
    end
  end

  let(:error_class) { described_class::ERROR_CLASSES.first }
  let(:exception) { error_class.new('already closed') }
  let(:conn) { MockConnection.new(exception) }

  describe '#safe_close_connection!' do
    context 'when called on an open connection' do
      it 'does not raise an error' do
        expect { described_class.safe_close_connection!(conn) }.not_to raise_error
      end
    end

    context 'when called on an already-closed connection' do
      context 'and the error pertains to double-closing' do
        it 'yields the error' do
          expect { described_class.safe_close_connection!(conn) }.not_to raise_error
          expect { |b| described_class.safe_close_connection!(conn, &b) }.to yield_with_args(exception)
        end
      end

      context 'and the error does not pertain to double-close' do
        let(:exception) { RuntimeError.new('sorry, no') }

        it 'yields and then raises the error' do
          expect { described_class.safe_close_connection!(conn) }.not_to raise_error
          expect { |b| described_class.safe_close_connection!(conn, &b) }.to yield_with_args(exception).and raise_error(exception)
        end
      end
    end
  end

  describe '#safe_connection_connection_standard!' do
    let(:env) {
      {
        connection: conn,
        ui: double('ui'),
      }
    }

    context 'when called on an open connection' do
      it 'does not raise an error' do
        expect { described_class.safe_close_connection_standard!(env) }.not_to raise_error
      end
    end

    context 'when called on an already-closed connection' do
      context 'and the error pertains to double-closing' do
        it 'logs a warning' do
          expect { described_class.safe_close_connection_standard!(env) }.not_to raise_error
          expect(env[:ui]).to receive(:warn).with(/^Encountered exception of class #{exception.class}: #{exception.message}/)
          expect { described_class.safe_close_connection_standard!(env) }.not_to raise_error
        end
      end

      context 'and the error does not pertain to double-close' do
        let(:exception) { RuntimeError.new('sorry, no') }

        it 'logs a warning and then raises the error' do
          expect { described_class.safe_close_connection_standard!(env) }.not_to raise_error
          expect(env[:ui]).to receive(:warn).with(/^Encountered exception of class #{exception.class}: #{exception.message}/)
          expect { |b| described_class.safe_close_connection_standard!(env) }.to raise_error(exception)
        end
      end
    end
  end
end
