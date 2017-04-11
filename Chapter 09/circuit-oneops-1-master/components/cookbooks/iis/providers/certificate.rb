require 'openssl'

def whyrun_supported?
  true
end

def load_current_resource
  @certificate_file = ::File.join('c:\windows\temp', "#{new_resource.name}.pfx")
end

action :import do
  converge_by("Import certificate in windows store") do
    password = new_resource.password
    raw_data = new_resource.raw_data
    certificate_file = @certificate_file

    key = OpenSSL::PKey.read(raw_data, password)
    cert = OpenSSL::X509::Certificate.new(raw_data)
    pkcs12 = OpenSSL::PKCS12.create(password, new_resource.name, key, cert)

    ::File.open(certificate_file, 'wb'){|f| f << pkcs12.to_der }
    thumbprint = OpenSSL::Digest::SHA1.new(cert.to_der).to_s

    powershell_script 'Import pfx certificate' do
      code "certutil.exe -p #{password} -importpfx #{certificate_file}"
      guard_interpreter :powershell_script
      not_if "if (Get-ChildItem -Path Cert:\\LocalMachine\\My | Where-Object {$_.Thumbprint -eq '#{thumbprint}'}) { $true } else { $false }"
    end

  end
end
