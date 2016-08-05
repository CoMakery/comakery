class CreateEthereumContract
  include Interactor

  def call
    project = context.project

    if project.transitioned_to_ethereum_enabled?
      EthereumTokenContractJob.perform_async(project.id)
    end
  end
end
