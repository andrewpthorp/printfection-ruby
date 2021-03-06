module Printfection
  class LineItem < Resource
    extend Actions::Retrieve
    extend Actions::Create
    include Actions::Update
    include Actions::Delete

    property :id,         transform_with: Transforms::Integer
    property :order_id,   transform_with: Transforms::Integer
    property :item_id,    transform_with: Transforms::Integer
    property :size_id,    transform_with: Transforms::Integer
    property :quantity,   transform_with: Transforms::Integer
    property :created_at, transform_with: Transforms::Date

    def self.uri
      "/lineitems"
    end

    def item
      @item ||= Item.retrieve(item_id)
    end

    def size
      @size ||= item.sizes.find { |s| s.id == size_id }
    end

  end
end

