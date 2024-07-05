
# AkaNet

AkaNet is an advanced iOS networking library built on top of Moya, offering extended features and enhancements for network communication in iOS applications.

## Features

- **Request Prioritization:** Prioritize network requests based on urgency or importance.
- **Cache Pooling:** Efficient management of network response caches with a pooling mechanism.
- **Multiple Cache Strategies:** Support for various caching strategies to optimize data retrieval and storage.
- **Streaming Support:** Seamless handling of large data streams for improved performance.
- **Persistent Connections:** Maintain long-lived connections to enhance network efficiency.

## Installation

To integrate AkaNet into your Xcode project using CocoaPods, add the following line to your `Podfile`:

```ruby
pod 'AkaNet'
```

Then, run the following command:

```bash
$ pod install
```

## Usage

1. **Initialization:**
   ```swift
   import AkaNet
   ```

2. **Creating Requests:**
   ```swift
   AkaNetworkService.POST(address: "/weaver/api/v1/conversation/go_on_reply", params: params) { data in
            if let response = GoOnReplyResp.deserialize(from: data) {
                completion(response)
            }
        }
   ```


For more detailed usage instructions and examples, please refer to the [Documentation](https://github.com/MidnightAck/AkaNet).

## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request for any improvements or feature requests.

## License

AkaNet is released under the MIT license. See [LICENSE](https://github.com/MidnightAck/AkaNet/blob/main/LICENSE) for more information.
