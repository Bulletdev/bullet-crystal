CREATE TABLE payments (
                          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                          correlation_id UUID NOT NULL UNIQUE,
                          amount DECIMAL(15,2) NOT NULL,
                          requested_at TIMESTAMP WITH TIME ZONE NOT NULL,
                          processor_type VARCHAR(20) NOT NULL,
                          processed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
                          fee_rate DECIMAL(5,4) NOT NULL,
                          fee_amount DECIMAL(15,2) NOT NULL
);

CREATE INDEX idx_payments_correlation_id ON payments(correlation_id);
CREATE INDEX idx_payments_processor_type ON payments(processor_type);
CREATE INDEX idx_payments_processed_at ON payments(processed_at);
CREATE INDEX idx_payments_requested_at ON payments(requested_at); 